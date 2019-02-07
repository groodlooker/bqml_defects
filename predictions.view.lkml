# If necessary, uncomment the line below to include explore_source.
# include: "manufacturing_defects.model.lkml"
view: input_data {
  derived_table: {
    explore_source: quality_issues {
      column: month_year_month {}
      column: month {}
      column: sales {}
      column: defects {}
      column: defect_ratio {}
      derived_column: four_month_average_ratio {
        sql: AVG(defect_ratio) OVER(ORDER BY month_year_month ASC
                                    ROWS BETWEEN 4 PRECEDING AND CURRENT ROW);;
      }
      derived_column: last_year_ratio {
        sql: LAG(defect_ratio) OVER(ORDER BY month_year_month ASC) ;;
      }

    }
  }
  dimension: month_year_month {
    type: date_month
  }
  dimension: month {
    type: number
  }
  dimension: sales {
    type: number
  }
  dimension: defects {
    type: number
  }
  dimension: defect_ratio {
    value_format: "#,##0%"
    type: number
  }
  dimension: four_month_average_ratio {
    value_format_name: percent_0
    type: number
  }
  dimension: last_year_ratio {
    type: number
    value_format_name: percent_0
  }
}

explore: input_data {}

## Model Creation ##
view: defect_ratio_regression {
  derived_table: {
    datagroup_trigger: manufacturing_defects_default_datagroup
    sql_create:
      CREATE OR REPLACE MODEL ${SQL_TABLE_NAME}
      OPTIONS(model_type='linear_reg'
        , labels=['defect_ratio']
        , min_rel_progress = 0.05
        , max_iteration = 50
        ) AS
      SELECT
         * EXCEPT(month_year_month,defects)
      FROM ${input_data.SQL_TABLE_NAME};;
  }
}

## Prediction Input Data ##
# If necessary, uncomment the line below to include explore_source.
# include: "predictions.view.lkml"

view: prediction_values {
  derived_table: {
    explore_source: input_data {
      column: month_year_month {}
      column: month {}
      column: sales {}
      column: last_year_ratio {}
      column: four_month_average_ratio {}
      filters: {
        field: input_data.month_year_month
        value: "2019/02/01 to 2019/02/28"
      }
    }
  }
}

## Predictions ##
view: defect_ratio_prediction {
  derived_table: {
    sql: SELECT * FROM ml.PREDICT(
          MODEL ${defect_ratio_regression.SQL_TABLE_NAME},
          (SELECT * FROM ${prediction_values.SQL_TABLE_NAME}));;
  }
  dimension: predicted_defect_ratio {
    type: number
    value_format_name: percent_0
  }
  dimension: month_year_month {}
}

explore: defect_ratio_prediction {}
