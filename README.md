# MDI Container Builder

The [Michigan Data Interface](https://midataint.github.io/) (MDI) 
is a framework for developing, installing and running 
Stage 1 HPC **pipelines** and Stage 2 interactive web applications 
(i.e., **apps**) in a standardized design interface.

This repository carries admin-only resource to create an Amazon Machine Image (AMI) for helping 
developers build Singularity container images from Amazon Web Services (AWS).

Information on AWS AMIs can be found here:  

- <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html>

Information on the Singularity container platform can be found here:

- <https://sylabs.io/guides/latest/user-guide/introduction.html>

Note: this repository is for building the container-builder AMI,
not the Singularity containers themselves. Container build actions 
are coded in the pipelines framework:

- <https://github.com/MiDataInt/mdi-pipelines-framework.git>

---
## General Information

### Summary of the AMI:

- **source AMI** = Ubuntu 20.04 standard image, X86_64
- **Linux user** = ubuntu, the AWS standard
- **region** = Ohio, us-east-2
- **instance type** = t3.medium (2 vCPU, 4 GB RAM)
- **storage** = 20 GB EBS SSD
- **Singularity** = installed in ~/singularity and ready to build container images
- **MDI repositories** = mdi frameworks installed in ~/mdi and ready for use

#### Linux operating system

Any Linux system can build Singularity images, but we use Ubuntu Linux
by default, with version 20.04 LTS being current as of this writing.

#### AWS region

AWS AMIs are region specific, i.e., they are only available to be used
for launching instances in the same region as the AMI itself. Because
the MDI uses a "Michigan first" approach, we build all AMIs in the
Ohio, us-east-2, AWS region, the one closest to Ann Arbor, MI.

#### Instance type

An AMI is not tied to a specific instance type, but we create the 
container builder with sufficient resources, i.e., t3 medium.

When launching a container builder instance, it is beneficial to 
select an instance type with more CPUs, which speeds R package
compilations and Singularity image compression (unfortunately, 
conda environment building doesn't benefit much from more CPUs at present, 
see [here](https://www.anaconda.com/blog/how-we-made-conda-faster-4-7)).

#### Storage

Storage volume size can be adjusted when a new EC2 instance is launched,
but we create the container builder with sufficient storage to build
several larger images. Developers can safely delete older images once 
they are pushed to a container registry.

#### MDI repositories

The installer uses the MiDataInt/mdi repo to install the MDI and all
of the frameworks independently of R.

---
## Instructions for creating the container-builder AMI

The steps below will clone the mdi-container-builder repo into a new EC2 
instance and execute the server configuration script to prepare for 
the build actions to be taken by developers in eventual instances.
The script prepares the operating system to run 'mdi build' by
installing Singularity, the MDI, and other system tools. 

### Launch an AWS instance

Launch an EC2 instance with the specifications listed above (or, choose
a different base OS or AWS region, if desired).

- <https://us-east-2.console.aws.amazon.com/ec2/v2/home?region=us-east-2#Instances:>

### Log in to the new instance using an SSH terminal

Details for how to log in to an AWS instance are amply documented by Amazon.

- <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html>

Among many choices, we typically use Visual Studio Code with a remote connection 
established via SSH:

- <https://code.visualstudio.com/docs/remote/remote-overview>

### Clone this repository

From within your terminal, i.e., bash command shell, on the new instance 
(note that git is pre-installed with Ubuntu 20.04):

```bash
cd ~
git clone https://github.com/MiDataInt/mdi-container-builder.git
```

### Check and run the server setup script

```bash
cd mdi-container-builder
bash ./initialize-container-builder.sh
```

It will take many minutes for all of the server components 
to be installed, in particular, Singularity.

### Secure the AMI for public distribution

Container builder images should be made public for anyone to use by
setting the Permissions in the AWS console after creating the AMI. 
In preparation for this public release, we follow the AWS guidelines
for securing shared AMIs:

- <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/building-shared-amis.html>

Specifically, immediately before creating the AMI, run the following script, 
which removes ssh keys and restricts root login permissions:

```bash
bash ~/mdi-container-builder/prepare-public-ami.sh
```

If the sequence above was followed, and no other manipulations were done to 
a running instance, there will be no other keys or access tokens on the disk 
to be copied into the image.

It is also critical to note that once the above commands are executed, the 
instance from which the Tier 2 AMI is to be created will not be accessible
if it is stopped and restarted. However, a new instance can always be launched
from the saved AMI.

### Save the AMI

From within the [AWS Management Console](https://aws.amazon.com/console/), 
select the running EC2 instance and execute:

Actions --> Images and templates --> Create image

The container builder image should be named and described according to the following conventions. We use a timestamp that can be used to infer the version of the 
relatively unchanging mdi-container-builder repo.

>**name**  
>mdi-container-builder_ubuntu-20.04_singularity-3.9.4_yyyy-mm-dd
>
>**description**  
>Michigan Data Interface, container builder image, Ubuntu 20.04, Singularity 3.9.4, yyyy-mm-dd

---
## Instructions for using the container-builder AMI

### Launch an AWS instance

Launch an EC2 instance with the specifications listed above (or, choose
a different instance type or storage amount, if desired).

<https://us-east-2.console.aws.amazon.com/ec2/v2/home?region=us-east-2#Instances:>

### Build a container

First, be sure you have edited either '_config.yml' and/or 'pipeline.yml'
to declare the type of containers you will support, and how.

Then, to build a suite level container:

```bash
mdi build --help
mdi build --suite GIT_USER/REPOSITORY_NAME
```

To build a pipeline-level container, first edit '~/mdi/config/suites.yml' as for
any MDI installation and run:

```bash
cd ~/mdi
nano config/suites.yml
./install.sh
mdi PIPELINE_NAME build --help
mdi PIPELINE_NAME build [OPTIONS]
```

In either case, you will be asked to confirm the build action and
the process will then build your container and push it to the 
registry specified in your configuration files.

### Make your container image public

Importantly, when a new image is pushed to your registry, e.g.,
the GitHub Container Registry, it will typically be marked Private.
Be sure the follow the instructions of your container registry
to make the image Public if you intend for others to use it.
