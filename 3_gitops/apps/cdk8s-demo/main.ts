import { Construct } from "constructs";
import { App, Chart, ChartProps } from "cdk8s";
import {
  IntOrString,
  KubeDeployment,
  KubeService,
  Quantity,
} from "./imports/k8s";
import { kebabCase } from "lodash";

export class MyChart extends Chart {
  constructor(
    scope: Construct,
    id: string,
    props: ChartProps = { disableResourceNameHashes: true }
  ) {
    super(scope, id, props);

    const label = {
      app: "cdk8s-demo",
      demo: kebabCase("knowledge sharing"),
    };
    new KubeDeployment(this, "deployment", {
      spec: {
        selector: { matchLabels: label },
        replicas: 1,
        template: {
          metadata: { labels: label },
          spec: {
            containers: [
              {
                name: "echoserver",
                image: "ealen/echo-server:latest",
                ports: [{ containerPort: 80 }],
                resources: {
                  limits: {
                    cpu: Quantity.fromString("0.5"),
                    memory: Quantity.fromString("256Mi"),
                  },
                  requests: {
                    cpu: Quantity.fromString("10m"),
                    memory: Quantity.fromString("10Mi"),
                  },
                },
              },
            ],
          },
        },
      },
    });
    new KubeService(this, "service", {
      spec: {
        type: "ClusterIP",
        ports: [{ port: 80, targetPort: IntOrString.fromNumber(80) }],
        selector: label,
      },
    });
  }
}

const app = new App();
new MyChart(app, "cdk8s-demo");
app.synth();
