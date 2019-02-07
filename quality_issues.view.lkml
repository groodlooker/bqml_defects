view: quality_issues {
  ##make sure this matches your SQL Table Name
  sql_table_name: online_retail.quality_issues ;;

  dimension: defects {
    type: number
    sql: ${TABLE}.defects ;;
  }

  dimension_group: month_year {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      month_num,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.month_year ;;
  }

  dimension: month {
    type: number
    sql: ${month_year_month_num} ;;
  }

  dimension: sales {
    type: number
    sql: ${TABLE}.sales ;;
  }

  dimension: defect_ratio {
    type: number
    value_format_name: percent_0
    sql: ${defects} / ${sales} ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}

## Data for Model Training ##
view: historic_data {
  derived_table: {
    explore_source: quality_issues {
      column: month_year_month {}
      column: sales {}
      column: defects {}
      column: month {}
      filters: {
        field: quality_issues.month_year_month
        value: "before 2019/01/31"
      }
    }
  }
}

## Model Creation ##
view: defect_ratio_model {
  derived_table: {
    datagroup_trigger: manufacturing_defects_default_datagroup
    sql_create:
      CREATE OR REPLACE MODEL ${SQL_TABLE_NAME}
      OPTIONS(model_type='linear_reg'
        , labels=['defects']
        , min_rel_progress = 0.05
        , max_iteration = 50
        ) AS
      SELECT
         * EXCEPT(month_year_month)
      FROM ${historic_data.SQL_TABLE_NAME};;
  }
}

## Values to Forecast ##
view: future_data {
  derived_table: {
    explore_source: quality_issues {
      column: month_year_month {}
      column: sales {}
      column: defects {}
      column: month {}
      filters: {
        field: quality_issues.month_year_month
        value: "after 2019/01/31"
      }
    }
  }
}

## Predictions ##
view: defect_predictions {
  derived_table: {
    sql: SELECT * FROM ml.PREDICT(
          MODEL ${defect_ratio_model.SQL_TABLE_NAME},
          (SELECT * FROM ${future_data.SQL_TABLE_NAME}));;
  }
  dimension: predicted_defects {
    type: number
  }
  dimension: month_year_month {}
}
