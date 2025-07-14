resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name = var.name_prefix != "" ? "${var.name_prefix}-igw" : "igw"
  }
}
