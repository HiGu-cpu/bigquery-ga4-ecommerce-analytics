/*
Project: GA4 Engagement and Purchase Correlation
Platform: Google BigQuery
Target Table: task5_corr_engagement_purchase_2021

Business Purpose:
Analyze the relationship between user engagement and purchase behavior.

Key Metrics:
- Session engagement
- Engagement time
- Purchase flag
- Correlation with purchase

Key SQL Concepts:
- CORR function
- COALESCE
- SAFE_CAST
- Event parameter extraction
- Session-level aggregation
*/

#standardSQL
CREATE OR REPLACE TABLE `basic-eon-484117-g5.sql_ara_proje_HiGu.task5_corr_engagement_purchase_2021` AS
WITH events AS (
  SELECT
    user_pseudo_id,

    -- session_id: event_params içindeki ga_session_id
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_id') AS session_id,

    -- session_engaged: int/string kaynaklarını INT64'e normalize et, NULL -> 0
    COALESCE(
      CAST((SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'session_engaged') AS INT64),
      SAFE_CAST((SELECT value.string_value
                 FROM UNNEST(event_params)
                 WHERE key = 'session_engaged') AS INT64),
      0
    ) AS session_engaged_int,

    -- engagement_time_msec: NULL -> 0
    COALESCE(
      (SELECT value.int_value
       FROM UNNEST(event_params)
       WHERE key = 'engagement_time_msec'),
      0
    ) AS engagement_time_msec,

    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _table_suffix BETWEEN '20210101' AND '20211231'
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,

    -- Oturum bazında engaged flag (oturum içinde 1 kez bile 1 ise 1)
    MAX(session_engaged_int) AS session_engaged_int,

    -- Oturum bazında toplam etkileşim süresi
    SUM(engagement_time_msec) AS total_engagement_time_msec,

    -- Satın alma: oturumda purchase varsa 1
    MAX(IF(event_name = 'purchase', 1, 0)) AS has_purchase
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY 1,2
),
final AS (
  SELECT
    -- Korelasyon (CORR): sayısal tip için FLOAT64 dönüşümü
    CORR(CAST(session_engaged_int AS FLOAT64), CAST(has_purchase AS FLOAT64)) AS corr_engaged_vs_purchase,
    CORR(CAST(total_engagement_time_msec AS FLOAT64), CAST(has_purchase AS FLOAT64)) AS corr_time_vs_purchase,

    -- Örneklem büyüklüğü
    COUNT(*) AS sessions_count,
    SUM(has_purchase) AS purchase_sessions_count
  FROM sessions
)
SELECT * FROM final;
