---
layout: default
---

See installation instructions at:

- [Dask](https://github.com/dask/helm-chart)

## Stable releases

{% assign dask = site.data.index.entries.dask | sort: 'created' | reverse %}
{% assign all_charts = dask %}
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