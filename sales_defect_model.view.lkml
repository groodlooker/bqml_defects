view: sales_defect_model {
  sql_table_name: online_retail.sales_defect_model ;;

  dimension: defects {
    type: number
    sql: ${TABLE}.defects ;;
  }

  dimension: model_name {
    type: string
    sql: ${TABLE}.model_name ;;
  }

  dimension_group: month_year {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.month_year ;;
  }

  dimension: sales {
    type: number
    sql: ${TABLE}.sales ;;
  }

  measure: count {
    type: count
    drill_fields: [model_name]
  }
}
