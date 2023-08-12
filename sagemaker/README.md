### Sagemaker Notebook

In variables file modify add_bucket_arn variable to include the buckets for which access is needed. 
Access to the mlops-nutrients public bucket is available by default - so it can be removed from the add_bucket_arn. 
Depending on the user's permissions some of the statements will have to be adjusted - specifically *, delete or modify permissions to be revoked for public buckets.

Provides an always on SageMaker Notebook instance that can speak to internal MetaData Service and Datastore.
This allows interactions with historical flows, inspection of executions and artifacts.

Depends on the output of the `infra` and `metaflow` projects.

Secrets are needed to access metaflow - follow instructions how to setup local vault server and add secrets.

To read more, see [the Metaflow docs](https://docs.metaflow.org/metaflow-on-aws/metaflow-on-aws#notebooks)

The link above (from metaflow repo) no longer works - instead there's a better guide on Sagemaker for Metaflow:
https://dev.to/aws-builders/going-to-production-with-github-actions-metaflow-and-aws-sagemaker-13oe

Sagemaker is notoriously difficult to install packages with on_start.sh and to make them available in the new env. 
This makes it a poor candidate for IAC, but it can be used for model development and collaboration (main usecase for WANDB as well).
'''!conda install metaflow -y
then check:
'''!metaflow status
* to make sure it points to proper service url
* metaflow experiments will be logged to metaflow service and cards available fro viewing