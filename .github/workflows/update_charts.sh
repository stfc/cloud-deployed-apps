#!/bin/bash

set -eo pipefail
updated_charts=()

helm repo add cloud-charts https://stfc.github.io/cloud-helm-charts/
helm repo add capi-addon-chart https://azimuth-cloud.github.io/cluster-api-addon-provider
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo update

for chart in ../../charts/staging/*; do
    chart_yaml="$chart/Chart.yaml"
    [ -f "$chart_yaml" ] || continue

    echo "Checking dependencies for $chart_yaml..."

    deps=$(yq e '.dependencies[]?.name' "$chart_yaml")

    modified=false

    for dep in $deps; do
        current_version=$(yq e ".dependencies[] | select(.name == \"$dep\") | .version" "$chart_yaml")

        # Find latest version from helm repo
        latest_version=$(helm search repo "$dep" -o yaml | yq e '.[0].version' -)

        if [[ "$latest_version" != "$current_version" && -n "$latest_version" ]]; then
        echo "Updating $dep in $chart: $current_version to $latest_version"
        yq -i ".dependencies[] |= (select(.name == \"$dep\") .version = \"$latest_version\")" "$chart_yaml"
        modified=true
        fi
    done

    if [ "$modified" = true ]; then
        updated_charts+=("$chart")
    fi
done