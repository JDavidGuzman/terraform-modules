output "network" {
  value = {
    vpc          = aws_vpc.main.id
    igw          = aws_internet_gateway.main.id
    subnets      = [for s in aws_subnet.main : { "name" : s.tags_all.Name, "id" : s.id }]
    route_tables = length(aws_route_table.main) > 1 ? { "public" : aws_route_table.main[0].id, "private" : aws_route_table.main[1].id } : { "public" : aws_route_table.main[0].id }
    elastic_ip   = length(aws_eip.main) == 1 ? { "public_ip" : aws_eip.main[0].public_ip, "private_ip" : aws_eip.main[0].private_ip } : null
    nat          = length(aws_nat_gateway.main) == 1 ? aws_nat_gateway.main[0].id : null
  }
}
