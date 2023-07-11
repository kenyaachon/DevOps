## Kubernetes

- tip 1
  you can create a pod without writing a YAML MANIFEST
  `$ kubectl run dnsutils --image=tutum/dnsutils`
- tip 2
  you can use tip 1 to performa DNS lookup
  ``$ kubectl exec dnsutils nslookup kubia-headless ```
