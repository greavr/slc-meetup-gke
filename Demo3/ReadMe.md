# slc-meetup-gke

```
cd Demo3/DockerImage
docker build . -t us.gcr.io/$DEVSHELL_PROJECT_ID/bad-pod
docker push us.gcr.io/$DEVSHELL_PROJECT_ID/bad-pod
```

Then run the containner with:
`docker run --privileged -d -p 8080:8080 gcr.io/$DEVSHELL_PROJECT_ID/bad-pod`\