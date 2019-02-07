## Change the connection to match yours ##
connection: "lookerdata"

# include all the views
include: "*.view"

datagroup: manufacturing_defects_default_datagroup {
  sql_trigger: SELECT MAX(month_year) FROM quality_issues;;
  max_cache_age: "1 hour"
}

persist_with: manufacturing_defects_default_datagroup

explore: quality_issues_predictions {
  from: quality_issues
  join: defect_predictions {
    sql_on: (FORMAT_TIMESTAMP('%Y-%m', CAST(defect_predictions.month_year_month  AS TIMESTAMP))) = ${quality_issues_predictions.month_year_month} ;;
    type: left_outer
    relationship: one_to_one
  }
}

explore: quality_issues {}
