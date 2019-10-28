---
layout: default
---

## Getting Started

{{ site.description }}

You can add this repository to your local helm configuration as follows :

```
helm repo add {{ site.repo_name }} {{ site.url }}
helm repo update
```

## Charts

{% for helm_chart in site.data.index.entries %}
{% assign title = helm_chart[0] | capitalize %}
{% assign all_charts = helm_chart[1] | sort: 'created' | reverse %}
{% assign latest_chart = all_charts[0] %}

### {{ title }}

{{ latest_chart.description }}

[Home]({{ latest_chart.home }}) \| [Source]({{ latest_chart.sources[0] }})

<table>
  <tr>
    <th>chart version</th>
    <th>app version</th>
    <th>date</th>
  </tr>
  {% for chart in all_charts %}
    {% unless chart.version contains "-" %}
    <tr>
      <td>
      <a href="{{ chart.urls[0] }}">
          {{ chart.name }}-{{ chart.version }}
      </a>
      </td>
      <td>
          {{ chart.appVersion }}
      </td>
      <td>
          <span class='date'>{{ chart.created | date_to_rfc822 }}</span>
      </td>
    </tr>
    {% endunless %}
  {% endfor %}
</table>

{% endfor %}