view: model_input_data {
  derived_table: {
    explore_source: sales_defect_model {
      column: month_year_month {}
      column: model_name {}
#       column: month_year_month_num {}
      column: sales {}
      column: defects {}
      filters: {
        field: sales_defect_model.month_year_month
        value: "before 2019/02/01"
      }
    }
  }
}

view: defects_regression {
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
      FROM ${model_input_data.SQL_TABLE_NAME};;
  }
}

view: future_sales {
  derived_table: {
    explore_source: sales_defect_model {
      column: month_year_month {}
      column: model_name {}
      column: sales {}
#       filters: {
#         field: sales_defect_model.month_year_month
#         value: "after 2019/02/01"
#       }
    }
  }
}

view: defects_predections {
  derived_table: {
    sql: SELECT * FROM ml.PREDICT(
          MODEL ${defects_regression.SQL_TABLE_NAME},
          (SELECT * FROM ${future_sales.SQL_TABLE_NAME}));;
  }
  dimension: predicted_defects {
    type: number
  }
  dimension_group: month_year_month {
    timeframes: [raw,month,date]
    type: time
    hidden: yes
  }
  dimension: model_name {
    hidden: yes
    type: number
  }
}

view: defects_regression_evaluation {
  derived_table: {
    sql: SELECT * FROM ml.EVALUATE(
          MODEL ${defects_regression.SQL_TABLE_NAME},
          (SELECT * FROM ${model_input_data.SQL_TABLE_NAME})) ;;
  }
  dimension: mean_absolute_error {type: number value_format_name:decimal_1}
  dimension: mean_squared_error {type: number value_format_name:decimal_1}
  dimension: mean_squared_log_error {type: number value_format_name:decimal_1}
  dimension: median_absolute_error {type: number value_format_name:decimal_1}
  dimension: r2_score {type: number}
  dimension: explained_variance {type: number value_format_name:decimal_2}
}

view: trip_count_training {
  derived_table: {
    sql: SELECT  * FROM ml.TRAINING_INFO(MODEL ${defects_regression.SQL_TABLE_NAME});;
  }
  dimension: training_run {type: number}
  dimension: iteration {type: number}
  dimension: loss {type: number}
  dimension: eval_loss {type: number}
  dimension: duration_ms {label:"Duration (ms)" type: number}
  dimension: learning_rate {type: number}
  measure: iterations {type:count}
  measure: total_loss {
    type: sum
    sql: ${loss} ;;
  }
  measure: total_training_time {
    type: sum
    label:"Total Training Time (sec)"
    sql: ${duration_ms}/1000 ;;
    value_format_name: decimal_1
  }
  measure: average_iteration_time {
    type: average
    label:"Average Iteration Time (sec)"
    sql: ${duration_ms}/1000 ;;
    value_format_name: decimal_1
  }
  set: detail {fields: [training_run,iteration,loss,eval_loss,duration_ms,learning_rate]}
}

explore: sales_defect_model {
  join: defects_predections {
    sql_on:
    ${sales_defect_model.month_year_month} = ${defects_predections.month_year_month_month}
    and
    ${sales_defect_model.model_name} = ${defects_predections.model_name};;
    relationship: one_to_one
    type: left_outer
  }
}

explore: defects_regression_evaluation {}

explore: trip_count_training {}

view: sales_defect_model {
  sql_table_name: online_retail.sales_defect_model ;;

  dimension: defects {
    type: number
    sql: ${TABLE}.defects ;;
  }

  parameter: choose_model {
    type: string
    default_value: "Corolla"
    suggest_dimension: model_name
  }

  dimension: selected_model {
    sql: {% parameter choose_model %} ;;
    type: string
  }

  parameter: expected_unit_sales {
    type: number
    default_value: "2500000"
  }

  dimension: input_unit_sales {
    type: number
    sql: {% parameter expected_unit_sales %} ;;
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
      week_of_year,
      month,
      month_num,
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
