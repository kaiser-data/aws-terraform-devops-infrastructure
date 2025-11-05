# back to the future infra (phase 1)
# 3-tier on 2 subnets: frontend (public), backend + db (private)
locals {
  project_name = "bttf-voting-app"
  environment  = "dev"
  owner        = "Marty McFly"
}
