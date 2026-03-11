const TOOL_LABELS = {
  web_search: "Searching the web",
  search_and_read: "Reading webpage",
  exec_command: "Executing command",
  shell: "Executing command",
  read_file: "Reading file",
  write_file: "Writing file",
  list_directory: "Listing directory",
  create_file: "Creating file",
  delete_file: "Deleting file",
  move_file: "Moving file",
  memory_store: "Storing in memory",
  memory_search: "Searching memory",
  vault_store: "Storing in vault",
  vault_search: "Searching vault",
  document_export: "Creating document",
  canvas_push: "Creating canvas",
  canvas_eval: "Updating canvas",
  vision: "Analyzing image",
  generate_image: "Generating image",
  code_run: "Executing code",
  synthesize: "Generating audio",
};

function getToolLabel(name) {
  if (!name) return "Processing...";
  return TOOL_LABELS[name] || name.replace(/_/g, " ");
}

export function ToolIndicator({ tool }) {
  if (!tool) return null;

  return (
    <div className="cc-tool-bar">
      <span className="cc-tool-spinner" />
      <span className="cc-tool-label">{getToolLabel(tool.name)}</span>
    </div>
  );
}
