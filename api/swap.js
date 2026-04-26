import { AppKit } from "@circle-fin/app-kit";
import { createViemAdapterFromPrivateKey } from "@circle-fin/adapter-viem-v2";

export default async function handler(req, res) {
  // ── ป้องกัน crash โดยไม่มี response ──────────────────────────────────────
  res.setHeader("Content-Type", "application/json");

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // ── ตรวจ body ─────────────────────────────────────────────────────────────
  let body = req.body;
  if (!body) {
    return res.status(400).json({ error: "Empty request body" });
  }
  if (typeof body === "string") {
    try {
      body = JSON.parse(body);
    } catch {
      return res.status(400).json({ error: "Invalid JSON body" });
    }
  }

  const { amountIn, direction } = body;

  if (!amountIn || !direction) {
    return res.status(400).json({ error: "Missing amountIn or direction" });
  }

  // ── ตรวจ env ──────────────────────────────────────────────────────────────
  if (!process.env.KIT_KEY) {
    return res.status(500).json({ error: "KIT_KEY not configured" });
  }
  if (!process.env.PRIVATE_KEY) {
    return res.status(500).json({ error: "PRIVATE_KEY not configured" });
  }

  try {
    const adapter = createViemAdapterFromPrivateKey({
      privateKey: process.env.PRIVATE_KEY,
    });

    const kit = new AppKit();

    const tokenIn = direction === "usdc_to_eurc" ? "USDC" : "EURC";
    const tokenOut = direction === "usdc_to_eurc" ? "EURC" : "USDC";

    const result = await kit.swap({
      from: { adapter, chain: "Arc_Testnet" },
      tokenIn,
      tokenOut,
      amountIn: String(amountIn),
      config: {
        kitKey: process.env.KIT_KEY,
      },
    });

    // ── log ดู structure ของ result ───────────────────────────────────────
    console.log("Swap result:", JSON.stringify(result, null, 2));

    return res.status(200).json({
      success: true,
      txHash: result?.txHash || result?.transactionHash || result?.hash || "",
      amountOut: result?.amountOut || result?.toAmount || "",
      explorerUrl: result?.explorerUrl || "",
      tokenIn,
      tokenOut,
      amountIn,
      raw: result,
    });
  } catch (err) {
    console.error("Swap error:", err);

    // ── ส่ง error กลับให้ครบเสมอ ไม่ crash ───────────────────────────────
    return res.status(500).json({
      error: "Swap failed",
      message: err?.message || String(err),
    });
  }
}
