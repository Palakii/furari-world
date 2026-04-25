import { AppKit } from "@circle-fin/app-kit";
import { createViemAdapterFromPrivateKey } from "@circle-fin/adapter-viem-v2";

export default async function handler(req, res) {
  // รับแค่ POST
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { amountIn, direction } = req.body;
  // direction: "usdc_to_eurc" หรือ "eurc_to_usdc"

  if (!amountIn || !direction) {
    return res.status(400).json({ error: "Missing amountIn or direction" });
  }

  try {
    // สร้าง adapter จาก private key
    const adapter = createViemAdapterFromPrivateKey({
      privateKey: process.env.PRIVATE_KEY,
    });

    const kit = new AppKit();

    // กำหนด tokenIn/tokenOut ตาม direction
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

    return res.status(200).json({
      success: true,
      txHash: result?.transactionHash || result?.txHash || "pending",
      tokenIn,
      tokenOut,
      amountIn,
    });
  } catch (err) {
    console.error("Swap error:", err);
    return res.status(500).json({
      error: "Swap failed",
      message: err.message,
    });
  }
}
