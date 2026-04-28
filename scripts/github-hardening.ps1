param(
  [Parameter(Mandatory = $true)]
  [string]$Owner,

  [Parameter(Mandatory = $true)]
  [string]$Repo,

  [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (-not $env:GITHUB_TOKEN) {
  throw "GITHUB_TOKEN is not set. Export a PAT with repo admin rights."
}

$headers = @{
  "Accept" = "application/vnd.github+json"
  "Authorization" = "Bearer $($env:GITHUB_TOKEN)"
  "X-GitHub-Api-Version" = "2022-11-28"
  "User-Agent" = "devsecops-hardening-script"
}

Write-Host "1/3 - Enabling repository template flag..."
$templateBody = @{
  is_template = $true
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Patch `
  -Uri "https://api.github.com/repos/$Owner/$Repo" `
  -Headers $headers `
  -Body $templateBody `
  -ContentType "application/json" | Out-Null

Write-Host "2/3 - Applying branch protection on '$Branch'..."
$protectionBody = @{
  required_status_checks = @{
    strict = $true
    contexts = @(
      "Quality Gate (Critical/High = FAIL)"
    )
  }
  enforce_admins = $true
  required_pull_request_reviews = @{
    dismiss_stale_reviews = $true
    require_code_owner_reviews = $true
    required_approving_review_count = 1
    require_last_push_approval = $true
  }
  restrictions = $null
  allow_force_pushes = $false
  allow_deletions = $false
  block_creations = $false
  required_conversation_resolution = $true
  lock_branch = $false
  allow_fork_syncing = $true
  required_linear_history = $true
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
  -Method Put `
  -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch/protection" `
  -Headers $headers `
  -Body $protectionBody `
  -ContentType "application/json" | Out-Null

Write-Host "3/3 - Configuring Actions required workflow..."
$workflowBody = @{
  strict_required_status_checks_policy = $true
  do_not_enforce_on_create = $false
  required_status_checks = @(
    @{
      context = "Quality Gate (Critical/High = FAIL)"
      app_id = -1
    }
  )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
  -Method Patch `
  -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch/protection/required_status_checks" `
  -Headers $headers `
  -Body $workflowBody `
  -ContentType "application/json" | Out-Null

Write-Host "Done. Repository hardening is applied."
