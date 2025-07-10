import boto3
import os

ENV = os.environ.get("ENV", "dev")
REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
INVENTORY_PATH = os.path.join(os.path.dirname(__file__), "../inventory/hosts")

ec2 = boto3.client("ec2", region_name=REGION)

def get_rtsp_private_ips():
    filters = [
        {"Name": "tag:Name", "Values": [f"{ENV}-rtsp"]},
        {"Name": "instance-state-name", "Values": ["running"]}
    ]
    reservations = ec2.describe_instances(Filters=filters)["Reservations"]
    ips = []
    for r in reservations:
        for inst in r["Instances"]:
            ips.append(inst["PrivateIpAddress"])
    return ips

def write_inventory(ips):
    with open(INVENTORY_PATH, "w") as f:
        f.write("[rtsp]\n")
        for ip in ips:
            f.write(f"{ip} ansible_user=ec2-user\n")

if __name__ == "__main__":
    ips = get_rtsp_private_ips()
    write_inventory(ips)
    print(f"Wrote {len(ips)} hosts to {INVENTORY_PATH}")