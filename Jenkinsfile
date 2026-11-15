pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-deployer
  containers:
    - name: buildkit
      image: moby/buildkit:v0.22.0
      command: ["cat"]
      tty: true
      securityContext:
        privileged: true
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "2"
          memory: "2Gi"
    - name: helm
      image: alpine/helm:4.3.2
      command: ["cat"]
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "500m"
          memory: "256Mi"
'''
    }
  }

  triggers {
    pollSCM('H/5 * * * *')
  }

  environment {
    IMAGE_REPO = 'docker.io/sathvik627/visit-counter'
    IMAGE_TAG  = "1.1.${BUILD_NUMBER}"
  }

  stages {
    stage('Build & Push Image') {
      steps {
        container('buildkit') {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                            usernameVariable: 'DOCKER_USER',
                                            passwordVariable: 'DOCKER_TOKEN')]) {
            sh '''
              set +x
              export DOCKER_CONFIG=/tmp/.docker
              mkdir -p "$DOCKER_CONFIG"
              AUTH=$(printf '%s:%s' "$DOCKER_USER" "$DOCKER_TOKEN" | base64 | tr -d '\\n')
              printf '{"auths":{"https://index.docker.io/v1/":{"auth":"%s"}}}' "$AUTH" > "$DOCKER_CONFIG/config.json"
              set -x
              buildctl-daemonless.sh build \
                --frontend dockerfile.v0 \
                --local context=app \
                --local dockerfile=app \
                --opt build-arg:APP_VERSION="$IMAGE_TAG" \
                --output type=image,name="$IMAGE_REPO:$IMAGE_TAG",push=true
            '''
          }
        }
      }
    }

    stage('Deploy with Helm') {
      steps {
        container('helm') {
          sh '''
            helm upgrade --install visit-counter charts/visit-counter \
              -n kubernetes-learning \
              -f charts/visit-counter/values-prod.yaml \
              --set image.tag="$IMAGE_TAG" \
              --wait --timeout 5m
          '''
        }
      }
    }
  }
}