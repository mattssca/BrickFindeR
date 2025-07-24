library(shiny)
library(httr)
library(jsonlite)
library(DT)
library(shinyWidgets)
library(bslib)

REBRICKABLE_API_KEY <- Sys.getenv("REBRICKABLE_API_KEY", "f723ac7b66ff693cbc82b3e24f290098")

get_set_info <- function(set_num) {
  url <- paste0("https://rebrickable.com/api/v3/lego/sets/", set_num, "/")
  res <- httr::GET(url, httr::add_headers(Authorization = paste("key", REBRICKABLE_API_KEY)))
  if (httr::status_code(res) != 200) return(NULL)
  data <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
  data
}

get_set_parts <- function(set_num) {
  base_url <- paste0("https://rebrickable.com/api/v3/lego/sets/", set_num, "/parts/")
  all_results <- list()  # Store each page's results
  page <- 1
  
  repeat {
    res <- httr::GET(base_url, httr::add_headers(Authorization = paste("key", REBRICKABLE_API_KEY)), query = list(page = page, page_size = 1000))
    if (httr::status_code(res) != 200) break
    
    data <- jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8"))
    if (is.null(data$results) || length(data$results) == 0) break
    
    # Store this page's results
    all_results[[page]] <- data$results
    
    # Check if there's a next page
    if (!("next" %in% names(data)) || is.null(data[["next"]]) || data[["next"]] == "" || is.na(data[["next"]])) break
    page <- page + 1
  }
  
  if (length(all_results) == 0) return(NULL)
  
  # Combine all pages into one data frame
  combined_results <- do.call(rbind, all_results)
  
  if (is.null(combined_results) || nrow(combined_results) == 0) return(NULL)
  
  # Debug: print structure to understand the data
  cat("API Result structure:\n")
  cat("Number of rows:", nrow(combined_results), "\n")
  cat("Column names:", paste(names(combined_results), collapse = ", "), "\n")
  
  # Flexible extraction based on actual structure
  get_nested_value <- function(df, col_path, default = NA) {
    tryCatch({
      if (length(col_path) == 1) {
        if (col_path %in% names(df)) {
          return(df[[col_path]])
        }
      } else {
        # For nested columns like part.part_img_url
        base_col <- col_path[1]
        nested_col <- col_path[2]
        if (base_col %in% names(df) && is.data.frame(df[[base_col]])) {
          if (nested_col %in% names(df[[base_col]])) {
            return(df[[base_col]][[nested_col]])
          }
        }
      }
      return(rep(default, nrow(df)))
    }, error = function(e) {
      return(rep(default, nrow(df)))
    })
  }
  
  # Try different possible column structures
  part_img <- get_nested_value(combined_results, c("part", "part_img_url"), "")
  if (all(part_img == "")) {
    part_img <- get_nested_value(combined_results, "part_img_url", "")
  }
  
  color_name <- get_nested_value(combined_results, c("color", "name"), "Unknown")
  if (all(color_name == "Unknown")) {
    color_name <- get_nested_value(combined_results, "color_name", "Unknown")
  }
  
  quantity <- get_nested_value(combined_results, "quantity", 1)
  
  df <- data.frame(
    Part = part_img,
    Color = color_name,
    Quantity = as.numeric(quantity),
    FoundCount = 0,
    stringsAsFactors = FALSE
  )
  
  cat("Final dataframe rows:", nrow(df), "\n")
  return(df)
}

app_ui <- fluidPage(
  theme = bs_theme(
    bg = "#ffffff",        # White background
    fg = "#333333",        # Dark text
    primary = "#dc3545",   # Red primary
    secondary = "#6c757d", # Grey secondary
    base_font = font_google("Roboto")
  ),
  tags$head(
    # Add FontAwesome for icons
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"),
    tags$style(HTML("
      body {
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .sidebar {
        background-color: #f8f9fa !important;
        border-right: 2px solid #dc3545;
      }
      .main-panel {
        background-color: #ffffff !important;
      }
      .well {
        background-color: #f8f9fa !important;
        border: 1px solid #dee2e6 !important;
        color: #333333 !important;
      }
      .form-control {
        background-color: #ffffff !important;
        border: 1px solid #6c757d !important;
        color: #333333 !important;
      }
      .form-control:focus {
        background-color: #ffffff !important;
        border-color: #dc3545 !important;
        box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25) !important;
        color: #333333 !important;
      }
      .set-img-container {
        display: flex;
        justify-content: center;
        align-items: center;
        margin-bottom: 10px;
      }
      .set-img-container img {
        max-width: 250px;
        max-height: 180px;
        border-radius: 10px;
        box-shadow: 0 4px 15px rgba(220, 53, 69, 0.3);
        border: 2px solid #dee2e6;
      }
      .set-title {
        text-align: center;
        font-size: 2.2em;
        font-weight: bold;
        margin-bottom: 10px;
        color: #dc3545;
        letter-spacing: 2px;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
      }
      .logo-container {
        text-align: center;
        margin-bottom: 20px;
        padding: 10px;
      }
      .app-logo {
        max-width: 350px;        /* Increased from 200px */
        max-height: 130px;       /* Increased from 80px */
        height: auto;
        filter: drop-shadow(2px 2px 4px rgba(220, 53, 69, 0.3));
        transition: filter 0.3s ease;
      }
      .app-logo:hover {
        filter: drop-shadow(2px 2px 8px rgba(220, 53, 69, 0.5));
      }
      .set-desc {
        text-align: center;
        font-size: 1.1em;
        color: #333333;
        margin-bottom: 15px;
        background-color: #f8f9fa;
        padding: 15px;
        border-radius: 8px;
        border: 1px solid #dee2e6;
      }
      @media (max-width: 600px) {
        .set-img-container img {
          max-width: 95vw;
          max-height: 120px;
        }
        .set-title {
          font-size: 1.3em;
        }
        .app-logo {
          max-width: 200px;      /* Increased from 150px */
          max-height: 80px;      /* Increased from 60px */
        }
        .set-desc {
          font-size: 0.95em;
        }
        .sidebar .form-group, .sidebar .form-control {
          font-size: 1.1em;
        }
        .dataTables_wrapper .dataTables_length, .dataTables_wrapper .dataTables_filter {
          font-size: 1.1em;
        }
      }
      .summary-box {
        background: linear-gradient(135deg, #f8f9fa, #e9ecef) !important;
        border-radius: 8px;
        padding: 12px 18px;
        margin-bottom: 12px;
        font-size: 1.1em;
        color: #333333 !important;
        box-shadow: 0 4px 15px rgba(220, 53, 69, 0.2);
        border: 1px solid #dc3545;
      }
      .instructions-link {
        text-align: center;
        margin-bottom: 10px;
      }
      .instructions-link a {
        color: #dc3545 !important;
        text-decoration: none;
      }
      .instructions-link a:hover {
        color: #c82333 !important;
        text-shadow: 0 0 8px #dc3545;
      }
      .controls-cell {
        text-align: center;
        white-space: nowrap;
      }
      .controls-cell .btn {
        margin: 0 2px;
      }
      .checkbox-control {
        transform: scale(1.2);
        accent-color: #dc3545;
      }
      .dataTables_scrollBody {
        border: 1px solid #dee2e6 !important;
        background-color: #ffffff !important;
      }
      .table {
        margin-bottom: 0;
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .table td, .table th {
        border-color: #dee2e6 !important;
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .table-striped tbody tr:nth-of-type(odd) {
        background-color: #f8f9fa !important;
      }
      .dataTables_wrapper {
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .dataTables_filter input {
        background-color: #ffffff !important;
        border: 1px solid #6c757d !important;
        color: #333333 !important;
      }
      .progress {
        background-color: #e9ecef !important;
      }
      .progress-bar {
        background-color: #dc3545 !important;
      }
      hr {
        border-color: #dee2e6 !important;
      }
      .help-block {
        color: #6c757d !important;
      }
      .btn-danger, .btn-danger:focus {
        background-color: #dc3545 !important;
        border-color: #dc3545 !important;
        color: #ffffff !important;
        box-shadow: 0 4px 15px rgba(220, 53, 69, 0.3) !important;
      }
      .btn-danger:hover {
        background-color: #c82333 !important;
        border-color: #bd2130 !important;
        box-shadow: 0 6px 20px rgba(220, 53, 69, 0.5) !important;
      }
      .btn-success, .btn-success:focus {
        background-color: #6c757d !important;
        border-color: #6c757d !important;
        color: #ffffff !important;
      }
      .btn-success:hover {
        background-color: #5a6268 !important;
        border-color: #545b62 !important;
      }
      .selectize-control .selectize-input {
        background-color: #ffffff !important;
        border: 1px solid #6c757d !important;
        color: #333333 !important;
      }
      .selectize-dropdown {
        background-color: #ffffff !important;
        border: 1px solid #6c757d !important;
        color: #333333 !important;
      }
      .selectize-dropdown .option {
        background-color: #ffffff !important;
        color: #333333 !important;
      }
      .selectize-dropdown .option:hover {
        background-color: #dc3545 !important;
        color: #ffffff !important;
      }
      .footer-credits {
        margin-top: 30px;
        padding: 20px;
        border-top: 2px solid #dc3545;
        background: linear-gradient(135deg, #f8f9fa, #e9ecef);
        border-radius: 8px;
      }
      .github-link {
        color: #dc3545 !important;
        text-decoration: none !important;
        font-weight: bold;
        transition: all 0.3s ease;
      }
      .github-link:hover {
        color: #c82333 !important;
        text-shadow: 0 0 8px rgba(220, 53, 69, 0.5);
        transform: translateY(-1px);
      }
      .footer-credits p {
        margin: 0;
        font-size: 1.1em;
      }
    "))
  ),
  titlePanel(NULL),
  sidebarLayout(
    sidebarPanel(
      # Logo section with fallback
      conditionalPanel(
        condition = "true",
        tags$div(class = "logo-container",
          tags$img(
            src = "logo.png", 
            alt = "BrickFindeR Logo", 
            class = "app-logo",
            onerror = "this.src='images/logo.png'; this.onerror=function(){this.style.display='none'; this.nextElementSibling.style.display='block';};"
          ),
          tags$div(
            class = "set-title", 
            style = "display: none;",
            "BrickFindeR"
          )
        )
      ),
      textInput("set_num", "Enter LEGO Set Number (e.g. 75192-1):", value = ""),
      actionBttn("search", "Find Pieces", style = "material-flat", color = "danger", block = TRUE),
      br(),
      uiOutput("set_image"),
      hr(),
      pickerInput("filter_color", "Filter by Color", choices = NULL, multiple = TRUE, options = list(`actions-box` = TRUE)),
      prettySwitch("show_missing", "Show Only Missing Pieces", value = FALSE, status = "danger")
    ),
    mainPanel(
      uiOutput("set_desc"),
      uiOutput("instructions_link"),
      progressBar(
        id = "progress_bar",
        value = 0,
        total = 100,
        display_pct = TRUE,
        status = "danger",
        striped = TRUE,
        title = "Build Progress"
      ),
      uiOutput("summary_box"),
      DTOutput("parts_table"),
      br(),
      textOutput("error_msg"),
      
      # Footer with credits
      hr(),
      div(class = "footer-credits",
          tags$p(
            "Developed with ❤️ by ",
            tags$a(
              href = "https://github.com/mattsada", 
              target = "_blank",
              class = "github-link",
              tags$i(class = "fab fa-github"), # GitHub icon (if you have FontAwesome)
              " mattsada"
            ),
            style = "text-align: center; margin: 20px 0; color: #6c757d;"
          )
      )
    )
  )
)

server <- function(input, output, session) {
  # Debug: Check if logo file exists
  logo_path <- file.path("www", "logo.png")
  if (file.exists(logo_path)) {
    cat("Logo file found at:", logo_path, "\n")
  } else {
    cat("Logo file NOT found. Checking alternatives...\n")
    if (file.exists("logo.png")) {
      cat("Logo found in root directory\n")
      # Add resource path for the current directory
      addResourcePath(prefix = "images", directoryPath = getwd())
    }
  }
  
  set_info <- eventReactive(input$search, {
    req(input$set_num)
    get_set_info(input$set_num)
  })
  
  # Store found counts for each part
  found_status <- reactiveVal(NULL)
  
  parts_data <- eventReactive(input$search, {
    req(input$set_num)
    df <- get_set_parts(input$set_num)
    if (is.null(df)) {
      found_status(NULL)
      return(data.frame())
    }
    found_status(df$FoundCount)
    updatePickerInput(session, "filter_color", choices = sort(unique(df$Color)), selected = NULL)
    df
  })
  
  # Instructions link
  output$instructions_link <- renderUI({
    info <- set_info()
    if (is.null(info) || is.null(info$set_url)) return(NULL)
    tags$div(
      class = "instructions-link",
      tags$a(
        href = paste0("https://rebrickable.com/sets/", info$set_num, "/"),
        target = "_blank",
        shiny::icon("book"),
        "View Building Instructions"
      )
    )
  })
  
  output$set_image <- renderUI({
    info <- set_info()
    if (is.null(info) || is.null(info$set_img_url) || info$set_img_url == "") return(NULL)
    tags$div(class = "set-img-container",
             tags$img(src = info$set_img_url, alt = "Set Image"))
  })
  
  output$set_desc <- renderUI({
    info <- set_info()
    if (is.null(info)) return(NULL)
    tags$div(
      class = "set-desc",
      tags$b(info$name), tags$br(),
      paste("Set Number:", info$set_num),
      if (!is.null(info$num_parts)) paste0(" | Pieces: ", info$num_parts)
    )
  })
  
  # Filtering logic
  filtered_parts <- reactive({
    df <- parts_data()
    found <- found_status()
    if (is.null(df) || nrow(df) == 0) return(df)
    # Apply color filter
    if (!is.null(input$filter_color) && length(input$filter_color) > 0) {
      idx <- which(df$Color %in% input$filter_color)
      df <- df[idx, , drop = FALSE]
      found <- found[idx]
    }
    # Apply missing filter
    if (isTRUE(input$show_missing)) {
      idx <- which(found < df$Quantity)
      df <- df[idx, , drop = FALSE]
      found <- found[idx]
    }
    df$FoundCount <- found
    df
  })
  
  # Summary box
  output$summary_box <- renderUI({
    df <- parts_data()
    found <- found_status()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    total <- sum(df$Quantity)
    found_total <- sum(found)
    missing_total <- total - found_total
    unique_missing <- sum(found < df$Quantity)
    tags$div(
      class = "summary-box",
      tags$b("Progress: "),
      sprintf("%d of %d pieces found (%.1f%%)", found_total, total, 100 * found_total / total), tags$br(),
      tags$b("Missing unique pieces: "), unique_missing, tags$br(),
      tags$b("Missing total quantity: "), missing_total
    )
  })
  
  # Progress bar updates
  observe({
    df <- parts_data()
    found <- found_status()
    if (is.null(df) || nrow(df) == 0) {
      updateProgressBar(session, "progress_bar", value = 0, total = 100)
      return()
    }
    total <- sum(df$Quantity)
    found_total <- sum(found)
    updateProgressBar(session, "progress_bar", value = found_total, total = total)
  })
  
  output$parts_table <- renderDT({
    df <- filtered_parts()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    # Render images as HTML <img> tags, column title "Part"
    df$Part <- ifelse(
      is.na(df$Part) | df$Part == "",
      "",
      sprintf('<img src="%s" height="40"/>', df$Part)
    )
    # Plus/minus buttons and checkmark
    df$Found <- mapply(function(found, qty) {
      if (found >= qty) {
        '<span style="color:green;font-size:1.5em;">&#10003;</span>'
      } else {
        ""
      }
    }, df$FoundCount, df$Quantity)
    
    # Different controls based on quantity
    df$Controls <- mapply(function(count, qty, idx) {
      if (qty == 1) {
        # Checkbox for single pieces
        checked <- if (count >= qty) "checked" else ""
        paste0('<div class="controls-cell"><input type="checkbox" class="form-check-input checkbox-control" ', checked, 
               ' onchange="Shiny.setInputValue(\'toggle_piece\', {row:', idx, ', checked: this.checked}, {priority: \'event\'})"/></div>')
      } else {
        # Plus/minus buttons for multiple pieces
        paste0('<div class="controls-cell">',
          '<button class="btn btn-sm btn-danger" onclick="Shiny.setInputValue(\'remove_piece\', {row:', idx, '}, {priority: \'event\'})">-</button> ',
          '<span style="margin: 0 8px; font-weight: bold;">', count, ' / ', qty, '</span> ',
          '<button class="btn btn-sm btn-success" onclick="Shiny.setInputValue(\'add_piece\', {row:', idx, '}, {priority: \'event\'})">+</button>',
          '</div>')
      }
    }, df$FoundCount, df$Quantity, seq_len(nrow(df)))
    
    df <- df[, c("Part", "Color", "Quantity", "Controls", "Found")]
    datatable(
      df,
      colnames = c("Part", "Color", "Quantity", "Controls", "Found"),
      escape = FALSE,
      options = list(
        pageLength = -1,  # Show all rows by default
        dom = 'ft',       # Remove length menu and info
        scrollY = "400px",
        scrollCollapse = TRUE
      ),
      rownames = FALSE
    )
  }, server = FALSE)
  
  # Mobile-friendly: scroll to table on search
  observeEvent(input$search, {
    session$sendCustomMessage(type = "scrollToTable", message = list())
  })
  
  # Plus/minus logic
  observeEvent(input$add_piece, {
    idx <- input$add_piece$row
    df <- filtered_parts()
    found <- found_status()
    if (!is.null(df) && idx > 0 && idx <= nrow(df)) {
      # Find the correct index in the full parts_data
      full_df <- parts_data()
      full_found <- found_status()
      part_idx <- which(full_df$Part == df$Part[idx] & full_df$Color == df$Color[idx] & full_df$Quantity == df$Quantity[idx])
      if (length(part_idx) == 1) {
        full_found[part_idx] <- min(full_found[part_idx] + 1, full_df$Quantity[part_idx])
        found_status(full_found)
      }
    }
  })
  
  observeEvent(input$remove_piece, {
    idx <- input$remove_piece$row
    df <- filtered_parts()
    found <- found_status()
    if (!is.null(df) && idx > 0 && idx <= nrow(df)) {
      # Find the correct index in the full parts_data
      full_df <- parts_data()
      full_found <- found_status()
      part_idx <- which(full_df$Part == df$Part[idx] & full_df$Color == df$Color[idx] & full_df$Quantity == df$Quantity[idx])
      if (length(part_idx) == 1) {
        full_found[part_idx] <- max(full_found[part_idx] - 1, 0)
        found_status(full_found)
      }
    }
  })
  
  # Checkbox toggle logic for single pieces
  observeEvent(input$toggle_piece, {
    idx <- input$toggle_piece$row
    checked <- input$toggle_piece$checked
    df <- filtered_parts()
    if (!is.null(df) && idx > 0 && idx <= nrow(df)) {
      # Find the correct index in the full parts_data
      full_df <- parts_data()
      full_found <- found_status()
      part_idx <- which(full_df$Part == df$Part[idx] & full_df$Color == df$Color[idx] & full_df$Quantity == df$Quantity[idx])
      if (length(part_idx) == 1) {
        full_found[part_idx] <- if (checked) 1 else 0
        found_status(full_found)
      }
    }
  })
  
  output$error_msg <- renderText({
    if (input$search == 0) return("")
    df <- parts_data()
    if (is.null(df) || nrow(df) == 0) {
      "No parts found or invalid set number/API key."
    } else {
      ""
    }
  })
  
  # JS for mobile-friendly scroll to table
  observe({
    session$sendCustomMessage(type = "initScroll", message = list())
  })
}

# JS for mobile-friendly scroll to table
jsCode <- "
Shiny.addCustomMessageHandler('scrollToTable', function(message) {
  var table = document.getElementById('parts_table');
  if(table) {
    table.scrollIntoView({behavior: 'smooth', block: 'start'});
  }
});
"

jsInit <- "
Shiny.addCustomMessageHandler('initScroll', function(message) {
  // No-op, just to ensure handler is registered
});
"

ui <- tagList(
  tags$head(tags$script(HTML(jsCode))),
  tags$head(tags$script(HTML(jsInit))),
  app_ui
)

shinyApp(ui, server)
