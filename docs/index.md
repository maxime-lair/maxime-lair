## Project start

This page will be used to record the installation of a self-hosted devops environment.

The end-goal is to have an infrastructure running several services:
- Prometheus & Grafana for monitoring purpose
- Node_exporter (for host metrics) and Cadvisor (for docker metrics) on each host
- Traefik to handle routing and load-balancing
- Web application powered by httpd

All these applications will be running inside dockers, as to be scalable in the future

It will start as a single host project and will slowly be turning into multiple-hosts

## First installation

# Docker

We need to install docker on each host, It has to be done through a sudo or root user as the final process will be running with root privileges (constraint of docker).

We follow the [instructions as per recommended](https://docs.docker.com/engine/install/centos/) to guide us through

We start off with the first docker installation









## Welcome to GitHub Pages

You can use the [editor on GitHub](https://github.com/maxime-lair/maxime-lair/edit/main/docs/index.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [Basic writing and formatting syntax](https://docs.github.com/en/github/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/maxime-lair/maxime-lair/settings/pages). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://docs.github.com/categories/github-pages-basics/) or [contact support](https://support.github.com/contact) and we’ll help you sort it out.
