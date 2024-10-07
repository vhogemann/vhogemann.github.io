---
layout: post  
title:  "Hosting a Bot for BlueSky on Google Cloud Run"  
tags: portuguese gcp cloud-run docker  
categories: hosting gcp cloud-run docker  
image: /assets/hosting-gcp-cloud-run.png  
---

![Hosting a Bot for BlueSky on Google Cloud Run](/assets/hosting-gcp-cloud-run.png)

Finding a place to host my personal projects is often more challenging than the project itself, mainly because I don’t want to spend money on it. So, I’m sharing the solution I found that works well for me.

But first, let me explain the problem I needed to solve: I have a [bot](https://github.com/vhogemann/rss2bsky) that does the following:

- Reads a list of RSS feeds  
- For each feed in the list, it reads the XML and extracts the items  
- Compares the new items with a list of already published ones  
- Publishes all the new items to BlueSky  
- Updates the list of published items  

So, I needed two things:

- A place to run the bot  
- A place to save the configuration and the list of published items  

## The Plan

[Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run) is a serverless solution. It has many features, but the ones that matter to me are:

- Easy to configure  
- Runs a Docker image with minimal setup  
- It has a [free tier](https://cloud.google.com/run/pricing)  
- I can mount a [Cloud Storage](https://cloud.google.com/storage/) bucket as a volume in the Docker image  

Just to be clear, I’m far from being an expert in infrastructure, cloud computing, or anything similar. Google Cloud's greatest merit is that it was the first platform I managed to get working!

## The Bot

To fit with what Cloud Run offers, here’s what I did:

- Set up a GitHub repository  
- Run the bot in Docker  
- The bot runs in hourly batches  
- Configuration is a JSON file  
- The list of posts from each feed is stored as a [NDJSON](https://en.wikipedia.org/wiki/JSON_streaming) file  

The cost of Cloud Storage is much lower than setting up a dedicated database, and JSON files are more than enough for what the bot does. I did consider using SQLite, but that would be overkill, and I imagine running SQLite on a Cloud Storage bucket isn’t a great idea (though I still plan to try it in the future).

## Docker

I’m using a multi-stage Dockerfile, one stage to build the application and the other to run the `jar` file. The key here is defining a volume at `/root/dev/json`, where the bot’s files will be stored.

My application is in Java, but the same principle applies to any other language.

```Dockerfile
FROM eclipse-temurin:21 AS build_image  
ENV APP_HOME=/root/dev/  
RUN mkdir -p $APP_HOME/src/main/java  
WORKDIR $APP_HOME  
COPY app/build.gradle settings.gradle gradlew gradlew.bat $APP_HOME  
COPY gradle $APP_HOME/gradle  
# download dependencies  
RUN ./gradlew build -x test --continue  
COPY . .  
RUN ./gradlew build  

FROM eclipse-temurin:21-jre  
WORKDIR /root/  
COPY --from=build_image /root/dev/app/build/libs/app.jar .  
RUN mkdir -p /root/dev/json  

# Set environment variables  
ENV JSON_PATH=/root/dev/json  

# Use this to access the JSON files  
VOLUME /root/dev/json  

CMD ["java","-jar","app.jar"]  
```

The configuration file is `source.json` and has the following format:

```json
[
  {
    "feedId": "example_feed",
    "name": "Example Feed",
    "rssUrl": "https://www.youtube.com/feeds/videos.xml?playlist_id=PLAYLIST_ID",
    "feedExtractor": "YOUTUBE",
    "bskyIdentity": "example.bsky.app",
    "bskyPassword": "example-app-password"
  }
]
```

The published items list is named `{feedId}.ndjson` and consists of JSON objects separated by new lines.

```json
{"sourceId":"example_feed","title":"Some title 1","url":"https://www.youtube.com/watch?v=w5ebcowAJD8"}
{"sourceId":"example_feed","title":"Some title 2","url":"https://www.youtube.com/watch?v=UE-k4hYHIDE"}
```

## Cloud Run

In Google Cloud, here’s what you need to create:

- A build in Cloud Build for your Docker image  
- A bucket in Cloud Storage to save your files  
- A new Job in Cloud Run  

### Build

The first step is to connect Cloud Build with your GitHub repository. Just click on `Connect Repository` and follow the steps.

At the end, simply choose `Dockerfile` as the build type and select the `Dockerfile` you want to use.

![Cloud Build](/assets/hosting-gcp-cloud-run/cloud-build.png)

### Bucket

Probably the easiest part—Cloud Storage will already be enabled because of the previous step (that’s where your Docker images go).

For me, all I needed to do was:

- Create a new private bucket  
- Upload my configuration file `source.json`  

![Cloud Storage Bucket](/assets/hosting-gcp-cloud-run/cloud-storage-bucket.png)

### Job

A Job in Cloud Run is a process that runs once and finishes. You create a new Job, select the Docker image you created, and configure the volume to mount the Cloud Storage bucket.

I chose the smallest VM size available in the cheapest region I could find, which means:

- 512MiB of RAM  
- 1 vCPU  

![Cloud Run Job](/assets/hosting-gcp-cloud-run/cloud-run-job.png)

#### Trigger

With the Job created, you can run it manually, but to schedule it to run periodically, you’ll need to create a Trigger.

For my bot, I set it up to run hourly, from 9 AM to 6 PM, Monday to Saturday. You do this using the [cron syntax](https://en.wikipedia.org/wiki/Cron):

```
0 9-18 * * 1-6
```

![Cloud Run Trigger](/assets/hosting-gcp-cloud-run/cloud-run-trigger.png)

And that’s it! The Job will run at the scheduled intervals, and the files will be read and saved in the bucket.

## Some Considerations, and Costs

It’s worth noting that this solution works for me because of the specific characteristics of the application I’m running:

- It’s not interactive; it can run in batches  
- It accesses the disk very little—each feed updates roughly once a day with one or two new posts  
- Everything I need in terms of logic is contained within a single Docker image  

Given all of that, the estimated monthly cost of this setup is an extravagant `€0.10`. So, if what you need fits within the same constraints I imposed on myself, I think it’s worth giving Google Cloud a try.

![Cloud Billing](/assets/hosting-gcp-cloud-run/cloud-billing.png)

I use the bot to manage several accounts that repost videos from my favourite science channels on YouTube. You can check it out on this BlueSky list:

- [Science Robots](https://bsky.app/profile/victor.hogemann.com/lists/3l5k4tq4ao623)

And here’s the source code on my GitHub:

- [rss2bsky](https://github.com/vhogemann/rss2bsky/)