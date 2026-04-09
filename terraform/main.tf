module "dev" {
  source = "./modules/ec2"

  instance_type = "t3.micro"
  ami           = "ami-0c1ac8a41498c1a9c" # eu-north-1 Ubuntu
  env           = "dev"
}

module "stage" {
  source = "./modules/ec2"

  instance_type = "t3.micro"
  ami           = "ami-0c1ac8a41498c1a9c"
  env           = "stage"
}

module "prod" {
  source = "./modules/ec2"

  instance_type = "t3.micro"
  ami           = "ami-0c1ac8a41498c1a9c"
  env           = "prod"
}
