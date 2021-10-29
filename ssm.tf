# Use AWS default patch baselines for centos
data "aws_ssm_patch_baseline" "centos_patch_baseline" {
  owner            = "AWS"
  name_prefix      = "AWS-"
  operating_system = "CENTOS"
}

locals {
  bastion_patch_group_name = "${var.vpc_name} Bastions"
}

# Keeping patch groups together with this locals block to reduce confusion.
resource "aws_ssm_patch_group" "bastion_patch_group" {
  baseline_id = data.aws_ssm_patch_baseline.centos_patch_baseline.id
  patch_group = local.bastion_patch_group_name
}

resource "aws_ssm_maintenance_window" "bastion_window" {
  name              = "bastion-patch-window"
  schedule          = var.bastion_patch_schedule
  schedule_timezone = var.schedule_timezone
  duration          = 1
  cutoff            = 0
}

resource "aws_ssm_maintenance_window_target" "bastion_targets" {
  window_id     = aws_ssm_maintenance_window.bastion_window.id
  name          = "bastion-patch-targets"
  description   = "Patches bastion boxes."
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Patch Group"
    values = [local.bastion_patch_group_name]
  }
}

resource "aws_ssm_maintenance_window_task" "patch_bastion_boxes" {
  name            = "patch-bastions"
  max_concurrency = 10
  max_errors      = 1
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.bastion_window.id

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.bastion_targets.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "SnapshotId"
        values = ["{{WINDOW_EXECUTION_ID}}"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }
}
