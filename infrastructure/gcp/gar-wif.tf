# 1. Google Artifact Registry (Already created based on your logs)
resource "google_artifact_registry_repository" "homelab_repo" {
  location      = "us-east1"
  repository_id = "homelab-repo"
  description   = "Docker repository for Sovereign Cloud homelab images"
  format        = "DOCKER"
}

# 2. Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

# 3. Fixed Provider (Added clear attribute mappings)
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  # Mapping GitHub JWT claims to GCP attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # This is usually where the "Error 400" happens. 
  # If you add an attribute_condition, it MUST use one of the keys from the mapping above.
  attribute_condition = "attribute.repository == 'vsingh55/homelab-ops'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 4. Service Account & IAM Binding (Crucial for the "Handshake")
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
}

resource "google_service_account_iam_member" "wif_sa_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  # This principalSet specifically allows ONLY your repo to impersonate this SA
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/vsingh55/homelab-ops"
}

resource "google_project_iam_member" "gar_writer" {
  project = "homelab-vijay"
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}