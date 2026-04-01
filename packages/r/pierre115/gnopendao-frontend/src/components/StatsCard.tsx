import { Card, CardContent } from "@/components/ui/card";
import { LucideIcon } from "lucide-react";

interface StatsCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  subtitle?: string;
}

export function StatsCard({ title, value, icon: Icon }: StatsCardProps) {
  return (
    <Card className="glass border-white/5 hover:border-purple-500/30 transition-all duration-300">
      <CardContent className="p-6">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-gradient-to-br from-purple-500/20 to-cyan-500/20 rounded-xl">
            <Icon className="h-5 w-5 text-purple-400" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">{title}</p>
            <h3 className="text-2xl font-bold text-white truncate mt-1">
              {value}
            </h3>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}