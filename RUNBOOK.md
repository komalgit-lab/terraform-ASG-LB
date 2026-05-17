# ALB + ASG Terraform Assignment – Step-by-Step Runbook

## Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.5 installed (`terraform -version`)
- IAM user/role with permissions for EC2, VPC, ELB, ASG

---

## STEP 1 – Get the latest AMI (optional but recommended)

```bash
aws ec2 describe-images \
  --owners amazon \
  --filters 'Name=name,Values=al2023-ami-*-x86_64' \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
  --output text
```

Paste the returned AMI ID into `terraform.tfvars` as `ami_id`.

---

## STEP 2 – Initialize Terraform

```bash
cd alb-asg-terraform
terraform init
```

Expected output: "Terraform has been successfully initialized!"

---

## STEP 3 – Validate & Plan

```bash
terraform validate        # checks syntax
terraform plan            # shows what will be created (~20 resources)
```

Review the plan. You should see:
- 1 VPC, 1 IGW, 2 subnets, 1 route table + 2 associations
- 1 ALB, 1 target group, 1 listener
- 2 security groups, 1 launch template, 1 ASG

---

## STEP 4 – Apply

```bash
terraform apply -auto-approve
```

Wait ~3 minutes. At the end you'll see:

```
Outputs:
  alb_dns_name = "demo-alb-123456789.us-east-1.elb.amazonaws.com"
  alb_url      = "http://demo-alb-123456789.us-east-1.elb.amazonaws.com"
  asg_name     = "demo-asg"
```

---

## STEP 5 – Validate Traffic

### Option A – Browser
Open the `alb_url` in your browser. You should see:
```
Hello from ALB + ASG Demo
Instance ID: i-0abc123...
AZ: us-east-1a
```

### Option B – curl loop (watch instance rotation)
```bash
ALB=$(terraform output -raw alb_dns_name)
for i in $(seq 1 10); do
  curl -s http://$ALB | grep -E "Instance|AZ"
  sleep 1
done
```

You should see requests being served by instances in BOTH AZs.

---

## STEP 6 – Test Failover (the key part of the assignment)

### 6a – Find the running instance IDs

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names demo-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,AvailabilityZone,HealthStatus]' \
  --output table
```

### 6b – Stop ONE instance

```bash
# Replace i-0abc123 with an actual instance ID from above
aws ec2 stop-instances --instance-ids i-0abc123
```

### 6c – Watch the ALB health check detect the failure

```bash
ALB=$(terraform output -raw alb_dns_name)

# Keep curling – traffic should KEEP WORKING even while one instance stops
for i in $(seq 1 30); do
  RESP=$(curl -s --max-time 3 http://$ALB | grep -E "Instance|AZ" || echo "  [no response]")
  echo "Request $i: $RESP"
  sleep 2
done
```

Expected behaviour:
- For ~20-40 seconds you'll only see the surviving instance's AZ
- After 1-2 minutes, the ASG launches a REPLACEMENT instance (min=2 enforced)
- Traffic stays alive the whole time — this proves failover works

### 6d – Confirm the ASG replaced the instance

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names demo-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,AvailabilityZone,HealthStatus]' \
  --output table
```

You'll see a brand-new instance ID in the stopped instance's AZ.

---

## STEP 7 – Outputs to include in your assignment report

```bash
terraform output                    # show all outputs
terraform output alb_dns_name       # just the DNS name
terraform show                      # full state (good for screenshots)
```

---

## STEP 8 – Clean up (avoid AWS charges)

```bash
terraform destroy -auto-approve
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| ALB returns 502 | Instances still starting; wait 60-90s for health checks to pass |
| No instances in ASG | Check AMI ID is valid for your region |
| `terraform init` fails | Check AWS credentials (`aws sts get-caller-identity`) |
| curl times out | Check ALB security group allows port 80 from 0.0.0.0/0 |

---

## Assignment Checklist

- [x] Terraform with modules (networking / alb / asg)
- [x] Input variables with defaults in variables.tf
- [x] Deployed to 2 AZs (us-east-1a + us-east-1b)
- [x] ASG with min=2, max=4 instances
- [x] ALB with health checks every 10s
- [x] Failover tested: stop instance → traffic continues → ASG replaces
- [x] `alb_dns_name` output — validate with curl/browser
