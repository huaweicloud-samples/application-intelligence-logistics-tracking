# ============================================
# CSMS - Secrets Management
# ============================================

resource "huaweicloud_csms_secret" "model_key" {
  name        = "${var.project_name}-model-key"
  secret_text = var.model_api_key
}
