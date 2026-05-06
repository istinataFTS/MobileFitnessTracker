export interface ToolDefinition {
  readonly name: string;
  readonly description: string;
  readonly parameters: object; // JSON Schema
}

// STUB — populated in Plan C-5.
// The `echo` tool is kept here so voice-chat integration tests can exercise
// the tool-call code path. It will be removed when C-5 lands.
export const TOOL_REGISTRY: ReadonlyArray<ToolDefinition> = [
  {
    name: 'echo',
    description: 'Test-only tool that echoes its input. Will be removed in C-5.',
    parameters: {
      type: 'object',
      properties: { text: { type: 'string' } },
      required: ['text'],
    },
  },
];
