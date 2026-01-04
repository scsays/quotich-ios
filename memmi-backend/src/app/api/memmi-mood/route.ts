import OpenAI from "openai";

export const runtime = "nodejs";

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function POST(req: Request) {
  try {
    const { quotes } = await req.json();

    if (!Array.isArray(quotes) || quotes.length === 0) {
      return Response.json({ mood: "Quietly Hungry" }, { status: 200 });
    }

    const clipped = quotes
      .map((q: any) => String(q).slice(0, 240))
      .slice(0, 40);

    const prompt = [
      "You are Memmi, a cute quote monster.",
      "Given these quotes from the last week, output a TWO-WORD mood phrase.",
      "Rules:",
      "- Exactly two words.",
      "- Title Case (e.g., Curiously Content).",
      "- No punctuation.",
      "- No emojis.",
      "",
      "Quotes:",
      ...clipped.map((q: string) => `- ${q}`),
    ].join("\n");

    const response = await client.responses.create({
      model: "gpt-4.1-mini",
      input: prompt,
    });

    const text = (response.output_text || "").trim();
    const mood = text.split(/\s+/).slice(0, 2).join(" ");

    return Response.json(
      { mood: mood || "Curiously Content" },
      { status: 200 }
    );
  } catch (error) {
    return Response.json(
      { mood: "Mildly Confused" },
      { status: 200 }
    );
  }
}