import { AppKit } from "@circle-fin/app-kit";
import { createViemAdapterFromPrivateKey } from "@circle-fin/adapter-viem-v2";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { amountIn, direction } = req.body;

  if (!amountIn || !direction) {
    return res.status(400).json({ error: "Missing amountIn or direction" });
  }

  if (!process.env.KIT_KEY) {
    return res.status(500).json({ error: "KIT_KEY not set in environment" });
  }

  if (!process.env.PRIVATE_KEY) {
    return res
      .status(500)
      .json({ error: "PRIVATE_KEY not set in environment" });
  }

  try {
    // ── ตรงตาม doc: createViemAdapterFromPrivateKey ────────────────────────
    const adapter = createViemAdapterFromPrivateKey({
      privateKey: process.env.PRIVATE_KEY,
    });

    const kit = new AppKit();

    // ── Arc Testnet รองรับแค่ USDC และ EURC ────────────────────────────────
    const tokenIn = direction === "usdc_to_eurc" ? "USDC" : "EURC";
    const tokenOut = direction === "usdc_to_eurc" ? "EURC" : "USDC";

    // ── ตรงตาม doc: kit.swap() ─────────────────────────────────────────────
    const result = await kit.swap({
      from: { adapter, chain: "Arc_Testnet" },
      tokenIn,
      tokenOut,
      amountIn: String(amountIn),
      config: {
        kitKey: process.env.KIT_KEY,
      },
    });

    return res.status(200).json({
      success: true,
      txHash: result?.txHash || "",
      explorerUrl: result?.explorerUrl || "",
      tokenIn,
      tokenOut,
      amountIn: result?.amountIn || amountIn,
      amountOut: result?.amountOut || "",
    });
  } catch (err) {
    console.error("Swap error:", err);
    return res.status(500).json({
      error: "Swap failed",
      message: err.message,
    });
  }
}
