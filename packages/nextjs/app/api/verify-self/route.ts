// packages/nextjs/app/api/verify-self/route.ts
import { NextResponse } from "next/server";
import { AllIds, DefaultConfigStore, SelfBackendVerifier } from "@selfxyz/core";

// Production Self.xyz verifier configuration
const createSelfVerifier = () => {
  return new SelfBackendVerifier(
    process.env.NEXT_PUBLIC_SELF_SCOPE || "trust-protocol-v1", // Your app's unique scope
    process.env.NEXT_PUBLIC_SELF_ENDPOINT || "", // Your public endpoint
    process.env.NODE_ENV !== "production", // true = testnet, false = mainnet
    AllIds, // Accept all document types (passport, EU ID, etc.)
    new DefaultConfigStore({
      minimumAge: 18,
      excludedCountries: [], // Add ["IRN", "PRK"] if needed
      ofac: false, // Set to true for production compliance
    }),
    "hex", // Use "hex" for wallet addresses
  );
};

export async function POST(req: Request) {
  try {
    console.log("Self.xyz verification request received");

    // Parse request body
    const body = await req.json();
    const { attestationId, proof, publicSignals, userContextData } = body;

    // Validate required fields
    if (!proof || !publicSignals || !attestationId || !userContextData) {
      console.error("Missing required verification data:", {
        hasProof: !!proof,
        hasPublicSignals: !!publicSignals,
        hasAttestationId: !!attestationId,
        hasUserContextData: !!userContextData,
      });

      return NextResponse.json(
        {
          status: "error",
          message: "Missing required verification data",
          required: ["proof", "publicSignals", "attestationId", "userContextData"],
        },
        { status: 400 },
      );
    }

    // Parse user context to extract wallet address
    let walletAddress: string;
    try {
      const contextData = typeof userContextData === "string" ? JSON.parse(userContextData) : userContextData;
      walletAddress = contextData.walletAddress;

      if (!walletAddress) {
        throw new Error("Wallet address not found in context data");
      }

      console.log("Verifying Self proof for wallet:", walletAddress);
    } catch (error) {
      console.error("Failed to parse userContextData:", error);
      return NextResponse.json(
        {
          status: "error",
          message: "Invalid userContextData format or missing walletAddress",
        },
        { status: 400 },
      );
    }

    // Initialize Self verifier
    const selfBackendVerifier = createSelfVerifier();

    // Verify the proof with Self.xyz
    console.log("Calling Self.xyz verification...");
    const verificationResult = await selfBackendVerifier.verify(attestationId, proof, publicSignals, userContextData);

    console.log("Self verification completed:", {
      isValid: verificationResult.isValidDetails.isValid,
      hasNullifier: !!verificationResult.discloseOutput?.nullifier,
    });

    if (verificationResult.isValidDetails.isValid) {
      // Extract verification data
      const nullifier = verificationResult.discloseOutput.nullifier;
      const disclosedData = verificationResult.discloseOutput;

      if (!nullifier) {
        console.error("Verification successful but no nullifier received");
        return NextResponse.json(
          {
            status: "error",
            message: "Invalid verification result: missing nullifier",
          },
          { status: 500 },
        );
      }

      console.log("Verification successful for wallet:", walletAddress);

      return NextResponse.json({
        status: "success",
        verified: true,
        data: {
          nullifier: nullifier,
          walletAddress: walletAddress,
          verificationTime: Date.now(),
          disclosedAttributes: {
            minimumAge: disclosedData.minimumAge,
            nationality: disclosedData.nationality,
            // Add other disclosed fields as configured
          },
        },
      });
    } else {
      // Verification failed
      console.error("Self verification failed:", verificationResult.isValidDetails);

      return NextResponse.json(
        {
          status: "error",
          verified: false,
          message: "Identity verification failed",
          details: process.env.NODE_ENV === "development" ? verificationResult.isValidDetails : undefined,
        },
        { status: 400 },
      );
    }
  } catch (error) {
    console.error("Self verification API error:", error);

    return NextResponse.json(
      {
        status: "error",
        message: error instanceof Error ? error.message : "Internal verification error",
        details: process.env.NODE_ENV === "development" ? error : undefined,
      },
      { status: 500 },
    );
  }
}

// Health check endpoint
export async function GET() {
  return NextResponse.json({
    status: "ok",
    service: "Self.xyz Verification API",
    environment: process.env.NODE_ENV,
    scope: process.env.NEXT_PUBLIC_SELF_SCOPE,
    timestamp: Date.now(),
  });
}
