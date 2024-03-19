#! /bin/bash

#create private repo in argocd 
argocd repo add git@github.com:DEL-ORG/s6-revive-chart-repo.git --ssh-private-key-path ~/.ssh/id_rsa




#create argocd project and restrict to repo git@github.com:DEL-ORG/s6-revive-chart-repo.git
cat <<EOF | kubectl apply -f -

apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: revive
  namespace: argocd
  # Finalizer that ensures that project is not deleted until it is not referenced by any application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # Project description
  description: revive Project

  # Allow manifests to deploy from any Git repos
  sourceRepos:
  - git@github.com:DEL-ORG/s6-revive-chart-repo.git

  # permit applications to deploy to the revive  namespace in any
  # Destination clusters can be identified by 'server', 'name', or both.
  destinations:
  - namespace: '*'
    server: '*'
    name: '*'
 

  sourceNamespaces:
  - 'argocd'
  - 'revive'


  # Allow all cluster-scoped resources to be created
  clusterResourceWhitelist:
  - group: ''
    kind: '*'

  # # Allow all namespaced-scoped resources to be created, except for ResourceQuota, LimitRange, NetworkPolicy
  # namespaceResourceBlacklist:
  # - group: ''
  #   kind: ResourceQuota
  # - group: ''
  #   kind: LimitRange
  # - group: ''
  #   kind: NetworkPolicy

  # Allow all namespaced-scoped resources from being created
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  



  roles:
  # A role which provides read-only access to all applications in the project
  - name: read-only
    description: Read-only privileges to my-project
    policies:
    - p, proj:revive:read-only, applications, get, revive*, allow
    groups:
    - revive-oidc-group

  # A role which provides sync privileges to only the revive application, e.g. to provide
  # sync privileges to a CI system
  - name: ci-role
    description: Sync privileges for revive-dev
    policies:
    - p, proj:revive:ci-role, applications, sync, revive/revive, allow

    # NOTE: JWT tokens can only be generated by the API server and the token is not persisted
    # anywhere by Argo CD. It can be prematurely revoked by removing the entry from this list.
    jwtTokens:
    - iat: 1535390316

  # # Sync windows restrict when Applications may be synced. https://argo-cd.readthedocs.io/en/stable/user-guide/sync_windows/
  # syncWindows:
  # - kind: allow
  #   schedule: '10 1 * * *'
  #   duration: 1h
  #   applications:
  #     - '*-prod'
  #   manualSync: true
  # - kind: deny
  #   schedule: '0 22 * * *'
  #   duration: 1h
  #   namespaces:
  #     - default
  # - kind: allow
  #   schedule: '0 23 * * *'
  #   duration: 1h
  #   clusters:
  #     - in-cluster
  #     - '*'

 
 

 

EOF







#! /bin/bash
cat <<EOF | kubectl apply -f -



apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: revive
  namespace: argocd
spec:
  destination:
    namespace: revive
    server: https://kubernetes.default.svc
  project: revive
  source:
    path: revive-project/
    repoURL: 'git@github.com:DEL-ORG/s6-revive-chart-repo.git'
    targetRevision: phase-12-deploy-charts
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true



EOF
