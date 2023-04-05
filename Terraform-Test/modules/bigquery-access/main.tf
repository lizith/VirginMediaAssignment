resource "google_bigquery_dataset_access" "dataset_access" {
  for_each = var.bigquery_role_assignment

  dataset_id = each.key
  role       = each.value.role
  user_by_email {
    email = each.value.user
  }
}