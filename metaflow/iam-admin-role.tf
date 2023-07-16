data "aws_iam_policy_document" "metaflow_user_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        module.metaflow.metadata_svc_ecs_task_role_arn
      ]
      type = "AWS"
    }
  }
}

resource "aws_iam_role" "metaflow_user_role" {
  count = var.custom_role ? 1 : 0
  name  = local.metaflow_user_role_name
  # Read more about ECS' `task_role` and `execution_role` here https://stackoverflow.com/a/49947471
  assume_role_policy = data.aws_iam_policy_document.metaflow_user_role_assume_role.json

  tags = module.common_vars.tags
}

data "aws_iam_policy_document" "metaflow_policy" {

  statement {
    effect = "Allow"

    actions = [
      "cloudformation:*"
    ]
    resources = concat(
      var.add_bucket_arn,
      ["arn:${var.iam_partition}:cloudformation:${local.aws_region}:${local.aws_account_id}:stack/${local.resource_prefix}*${local.resource_suffix}"]
    )
  }

  statement {
    actions = [
      "s3:*Object"
    ]

    effect = "Allow"

    resources = concat(
      [ for arn in var.add_bucket_arn : "${arn}/*" ],
      ["${module.metaflow.metaflow_s3_bucket_arn}/*"]
    )

    # resources = [
    #   "${module.metaflow.metaflow_s3_bucket_arn}/*",
    # ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sagemaker:*",
    ]

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:notebook-instance/${local.resource_prefix}*${local.resource_suffix}",
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:notebook-instance-lifecycle-config/basic*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:${var.iam_partition}:iam::${local.aws_account_id}:role/${local.resource_prefix}*${local.resource_suffix}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:*"
    ]

    resources = [
      "arn:${var.iam_partition}:kms:${local.aws_region}:${local.aws_account_id}:key/"
    ]
  }

    # Add the new statement for ecs:DescribeCluster permission
  statement {
    effect = "Allow"

    actions = [
      "ecs:*"
    ]

    resources = [
      "*"  # Adjust the resource value if necessary
    ]
  }
}


data "aws_iam_policy_document" "batch_perms" {
  statement {
    sid = "JobsPermissions"

    effect = "Allow"

    actions = [
      "batch:*",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "DefinitionsPermissions"

    effect = "Allow"

    actions = [
      "batch:*"
    ]

    resources = [
      module.metaflow.METAFLOW_BATCH_JOB_QUEUE,
      "arn:${var.iam_partition}:batch:${local.aws_region}:${local.aws_account_id}:job-definition/*:*",
    ]
  }
}

data "aws_iam_policy_document" "custom_s3_list_access" {
  statement {
    sid = "BucketAccess"

    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = concat(
      var.add_bucket_arn,
      [module.metaflow.metaflow_s3_bucket_arn]
    )

    # resources = [
    #   module.metaflow.metaflow_s3_bucket_arn,
    # ]
  }
}

data "aws_iam_policy_document" "log_perms" {
  statement {
    sid = "GetLogs"

    effect = "Allow"

    actions = [
      "logs:*"
    ]

    resources = [
      "arn:${var.iam_partition}:logs:${local.aws_region}:${local.aws_account_id}:log-group:*:log-stream:*",
    ]
  }
}

data "aws_iam_policy_document" "allow_sagemaker" {
  statement {
    sid = "AllowSagemakerCreate"

    effect = "Allow"

    actions = [
      "sagemaker:*"
    ]

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:training-job/*",
    ]
  }

  statement {
    sid = "AllowSagemakerDescribe"

    effect = "Allow"

    actions = [
      "sagemaker:*"
    ]

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:training-job/*",
    ]
  }
}

data "aws_iam_policy_document" "allow_step_functions" {
  statement {
    sid = "TasksAndExecutionsGlobal"

    effect = "Allow"

    actions = [
      "states:*"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "StateMachines"

    effect = "Allow"

    actions = [
      "states:*"
    ]

    resources = [
      "arn:${var.iam_partition}:states:${local.aws_region}:${local.aws_account_id}:stateMachine:*",
    ]
  }
}

data "aws_iam_policy_document" "allow_event_bridge" {
  statement {
    sid = "RuleMaintenance"

    effect = "Allow"

    actions = [
      "events:*",
    ]

    resources = [
      "arn:${var.iam_partition}:events:${local.aws_region}:${local.aws_account_id}:rule/*",
    ]
  }

  statement {
    sid = "PutRule"

    effect = "Allow"

    actions = [
      "events:*",
    ]

    resources = [
      "arn:${var.iam_partition}:events:${local.aws_region}:${local.aws_account_id}:rule/*",
    ]

    condition {
      test = "Null"
      values = [
        true
      ]
      variable = "events:source"
    }
  }
}

resource "aws_iam_role_policy" "grant_metaflow_policy" {
  count  = var.custom_role ? 1 : 0
  name   = "metaflow"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.metaflow_policy.json
}

resource "aws_iam_role_policy" "grant_batch_perms" {
  count  = var.custom_role ? 1 : 0
  name   = "batch"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.batch_perms.json
}

resource "aws_iam_role_policy" "grant_custom_s3_list_access" {
  count  = var.custom_role ? 1 : 0
  name   = "s3_list"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.custom_s3_list_access.json
}

resource "aws_iam_role_policy" "grant_log_perms" {
  count  = var.custom_role ? 1 : 0
  name   = "log"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.log_perms.json
}

resource "aws_iam_role_policy" "grant_allow_sagemaker" {
  count  = var.custom_role ? 1 : 0
  name   = "sagemaker"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.allow_sagemaker.json
}

resource "aws_iam_role_policy" "grant_allow_step_functions" {
  count  = var.custom_role ? 1 : 0
  name   = "step_functions"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.allow_step_functions.json
}

resource "aws_iam_role_policy" "grant_allow_event_bridge" {
  count  = var.custom_role ? 1 : 0
  name   = "event_bridge"
  role   = aws_iam_role.metaflow_user_role[0].name
  policy = data.aws_iam_policy_document.allow_event_bridge.json
}
