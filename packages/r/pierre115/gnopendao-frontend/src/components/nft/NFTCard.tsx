import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { NFTListing } from "@/lib/types";
import { ShoppingCart, Loader2 } from "lucide-react";
import Image from "next/image";
import { useState } from "react";

interface NFTCardProps {
  listing: NFTListing;
  onBuy?: () => void;
  isLoading?: boolean;
}

export function NFTCard({ listing, onBuy, isLoading = false }: NFTCardProps) {
  const priceInGNOT = (listing.price / 1000000).toFixed(2);

  // Utiliser directement l'image du backend (plus de fallback hardcodé)
  const getImageUrl = () => {
    if (listing.image && listing.image.trim() !== '' && listing.image !== '""') {
      return listing.image.trim();
    }
    return ''; // Pas d'image, on retourne vide
  };

  const [imageSrc, setImageSrc] = useState(getImageUrl());

  // Nettoyer le nom
  const cleanName = listing.name?.trim().replace(/[""]/g, '') || '';
  const nftName = (cleanName && cleanName !== 'string)' && cleanName.length > 0)
    ? cleanName
    : `NFT #${listing.tokenId}`;

  // Gestionnaire d'erreur d'image
  const handleImageError = () => {
    console.warn(`Failed to load image for NFT ${listing.tokenId}:`, listing.image);
    // En cas d'erreur, on affiche juste un placeholder vide au lieu de forcer une image
    setImageSrc('');
  };

  return (
    <Card className="overflow-hidden glass glow-hover transition-all duration-300 hover:scale-105">
      <div className="aspect-square relative bg-secondary">
        <Image
          src={imageSrc}
          alt={nftName}
          fill
          className="object-cover"
          onError={handleImageError}
          unoptimized={imageSrc.includes('placeholder')}
        />
        <Badge className="absolute top-2 right-2 bg-purple-500">
          #{listing.tokenId}
        </Badge>
      </div>

      <CardContent className="p-4">
        <div className="space-y-2">
          <h3 className="font-semibold text-sm truncate">{nftName}</h3>

          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Price</span>
            <span className="text-lg font-bold text-purple-500">
              {priceInGNOT} GNOT
            </span>
          </div>

          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <span>Seller</span>
            <span className="font-mono">
              {listing.seller.slice(0, 6)}...{listing.seller.slice(-4)}
            </span>
          </div>
        </div>
      </CardContent>

      <CardFooter className="p-4 pt-0">
        <Button
          className="w-full bg-gradient-to-r from-purple-500 to-cyan-500 hover:from-purple-600 hover:to-cyan-600"
          onClick={onBuy}
          disabled={isLoading}
        >
          {isLoading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Processing...
            </>
          ) : (
            <>
              <ShoppingCart className="mr-2 h-4 w-4" />
              Buy Now
            </>
          )}
        </Button>
      </CardFooter>
    </Card>
  );
}