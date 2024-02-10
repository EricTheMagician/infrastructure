{
  version = "1.0.1";
  cache = true;
  endpoints = {
    custom = [
      {
        name = "Mistral";
        apiKey = "\${MISTRAL_API_KEY}";
        baseURL = "https://api.mistral.ai/v1";
        models = {
          default = [
            "mistral-tiny"
            "mistral-small"
            "mistral-medium"
          ];
          fetch = true;
        };
        titleConvo = true;
        titleMethod = "completion";
        titleModel = "mistral-tiny";
        summarize = false;
        summaryModel = "mistral-tiny";
        forcePrompt = false;
        modelDisplayLabel = "Mistral";
        addParams = {
          safe_prompt = true;
        };
        dropParams = [
          "stop"
          "user"
          "frequency_penalty"
          "presence_penalty"
        ];
      }
      {
        name = "OpenRouter";
        apiKey = "\${OPENROUTER_KEY}";
        baseURL = "https://openrouter.ai/api/v1";
        models = {
          default = [
            "gpt-3.5-turbo"
          ];
          fetch = true;
        };
        titleConvo = true;
        titleModel = "gpt-3.5-turbo";
        summarize = false;
        summaryModel = "gpt-3.5-turbo";
        forcePrompt = false;
        modelDisplayLabel = "OpenRouter";
      }
    ];
  };
}
