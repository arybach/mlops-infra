env = "mlops"

aws_region = "ap-southeast-1"

# Setting min vpcus and desired vcpus to 0 to prevent accidental cost accumulation.
# These settings will result in longer job startup times as AWS boots up the necessary compute resources.
cpu_max_compute_vcpus     = 16
cpu_min_compute_vcpus     = 0
cpu_desired_compute_vcpus = 0

large_cpu_max_compute_vcpus     = 16
large_cpu_min_compute_vcpus     = 0
large_cpu_desired_compute_vcpus = 0

gpu_max_compute_vcpus     = 12
gpu_min_compute_vcpus     = 0
gpu_desired_compute_vcpus = 0

enable_step_functions = true

access_list_cidr_blocks = []
