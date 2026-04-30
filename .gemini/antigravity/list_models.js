async function listModels() {
  const geminiKey = "AIzaSyA-ADvYnr_DpnGVbfwASTTmexC71ySJExc";
  const url = `https://generativelanguage.googleapis.com/v1/models?key=${geminiKey}`;
  
  try {
    const resp = await fetch(url);
    const data = await resp.json();
    console.log("Available Models:", JSON.stringify(data, null, 2));
  } catch (e) {
    console.error("Error:", e);
  }
}

listModels();
