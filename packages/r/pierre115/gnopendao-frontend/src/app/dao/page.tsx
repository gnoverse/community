"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useState, useEffect } from "react";
import { Header } from "@/components/Header";
import { getActiveProposals, getFinishedProposals, voteOnProposal, tallyProposal, getDAOMembersCount } from "@/lib/realm-calls";
import { ThumbsUp, ThumbsDown, Users, FileText, Loader2, Archive, CheckCircle, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default function DAOPage() {
  const [votingProposalId, setVotingProposalId] = useState<number | null>(null);
  const [tallyingProposalId, setTallyingProposalId] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<"active" | "archive">("active");
  const queryClient = useQueryClient();

  const { data: activeProposals = [], isLoading: isLoadingActive } = useQuery({
    queryKey: ["activeProposals"],
    queryFn: getActiveProposals,
    retry: false,
    refetchOnWindowFocus: false,
  });

  const { data: finishedProposals = [], isLoading: isLoadingFinished } = useQuery({
    queryKey: ["finishedProposals"],
    queryFn: getFinishedProposals,
    retry: false,
    refetchOnWindowFocus: false,
  });

  const { data: membersCount = 0 } = useQuery({
    queryKey: ["daoMembers"],
    queryFn: getDAOMembersCount,
    retry: false,
    refetchOnWindowFocus: false,
  });

  // Combine all proposals for stats
  const allProposals = [...activeProposals, ...finishedProposals];

  // Filter proposals based on active tab
  // For archive tab, reverse order to show most recent first
  const filteredProposals = activeTab === "active" ? activeProposals : [...finishedProposals].reverse();
  const isLoading = activeTab === "active" ? isLoadingActive : isLoadingFinished;

  const handleVote = async (proposalId: number, choice: "yes" | "no") => {
    console.log(`🗳️ [handleVote] Voting on proposal ${proposalId}: ${choice}`);

    // Check if wallet is connected
    if (!window.adena) {
      alert("Please install Adena wallet extension");
      return;
    }

    try {
      const account = await window.adena.GetAccount();
      if (!account) {
        alert("Please connect your Adena wallet first");
        return;
      }
    } catch (error) {
      alert("Please connect your Adena wallet first");
      return;
    }

    setVotingProposalId(proposalId);

    try {
      const result = await voteOnProposal(proposalId, choice);
      console.log("✅ Vote successful:", result);
      alert(`Vote "${choice}" submitted successfully!`);
      queryClient.invalidateQueries({ queryKey: ["activeProposals"] });
      queryClient.invalidateQueries({ queryKey: ["finishedProposals"] });
    } catch (error: any) {
      console.error("❌ Vote failed:", error);
      alert(`Vote failed: ${error.message || "Please try again"}`);
    } finally {
      setVotingProposalId(null);
    }
  };

  const handleTally = async (proposalId: number) => {
    console.log(`⚖️ [handleTally] Executing proposal ${proposalId}`);

    // Check if wallet is connected
    if (!window.adena) {
      alert("Please install Adena wallet extension");
      return;
    }

    try {
      const account = await window.adena.GetAccount();
      if (!account) {
        alert("Please connect your Adena wallet first");
        return;
      }
    } catch (error) {
      alert("Please connect your Adena wallet first");
      return;
    }

    setTallyingProposalId(proposalId);

    try {
      const result = await tallyProposal(proposalId);
      console.log("✅ Tally successful:", result);
      alert("Proposal executed successfully!");
      queryClient.invalidateQueries({ queryKey: ["activeProposals"] });
      queryClient.invalidateQueries({ queryKey: ["finishedProposals"] });
    } catch (error: any) {
      console.error("❌ Tally failed:", error);
      alert(`Execution failed: ${error.message || "Please try again"}`);
    } finally {
      setTallyingProposalId(null);
    }
  };

  const getVotePercentage = (votes: number, total: number) => {
    if (total === 0) return 0;
    return Math.round((votes / total) * 100);
  };

  return (
    <div className="min-h-screen bg-slate-950 overflow-hidden relative">
      <Header />

      {/* Animated Grid Background */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute inset-0 bg-grid-pattern"></div>
        <div className="absolute inset-0 bg-gradient-radial from-purple-900/30 via-transparent to-transparent"></div>
      </div>

      {/* Floating orbs */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="orb orb-1"></div>
        <div className="orb orb-2"></div>
        <div className="orb orb-3"></div>
      </div>

      <main className="relative z-10">
        {/* Hero section */}
        <div className="container mx-auto px-4 pt-20 pb-12">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <div className="relative py-8">
              <h1 className="text-6xl font-black tracking-tighter relative z-10">
                <span className="holographic-text inline-block">
                  DAO Governance
                </span>
              </h1>
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-32 bg-gradient-to-r from-purple-500/30 via-pink-500/30 to-cyan-500/30 blur-3xl animate-pulse-slow"></div>
            </div>

            <p className="text-lg text-slate-400 font-light max-w-xl mx-auto">
              Vote on proposals to shape the future of the marketplace
            </p>

            {/* Stats badges */}
            <div className="flex items-center justify-center gap-8 py-6">
              <StatBadge icon={FileText} value={activeProposals.length} label="Active Proposals" />
              <div className="w-px h-12 bg-gradient-to-b from-transparent via-purple-500 to-transparent"></div>
              <StatBadge icon={Users} value={membersCount} label="DAO Members" />
              <div className="w-px h-12 bg-gradient-to-b from-transparent via-cyan-500 to-transparent"></div>
              <StatBadge icon={ThumbsUp} value={allProposals.reduce((acc, p) => acc + p.totalVotes, 0)} label="Total Votes" />
            </div>
          </div>
        </div>

        {/* Proposals Grid */}
        <div className="container mx-auto px-4 pb-20">
          <div className="max-w-4xl mx-auto">
            {/* Header section with tabs */}
            <div className="flex items-center justify-between mb-8">
              <div className="flex items-center gap-6">
                <div className="flex items-center gap-3">
                  <div className="w-1 h-8 bg-gradient-to-b from-purple-500 to-cyan-500 rounded-full"></div>
                  <h2 className="text-2xl font-bold text-white">Proposals</h2>
                </div>

                {/* Tabs */}
                <div className="flex items-center gap-1 glass rounded-full p-1">
                  <button
                    onClick={() => setActiveTab("active")}
                    className={`px-4 py-2 text-sm font-medium rounded-full transition-all ${
                      activeTab === "active"
                        ? "bg-white/10 text-white"
                        : "text-slate-400 hover:text-white hover:bg-white/5"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <FileText className="h-4 w-4" />
                      Active
                    </div>
                  </button>
                  <button
                    onClick={() => setActiveTab("archive")}
                    className={`px-4 py-2 text-sm font-medium rounded-full transition-all ${
                      activeTab === "archive"
                        ? "bg-white/10 text-white"
                        : "text-slate-400 hover:text-white hover:bg-white/5"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <Archive className="h-4 w-4" />
                      Archive
                    </div>
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2 text-sm text-slate-400">
                <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span>{activeTab === "active" ? "Live Voting" : "Ended"}</span>
              </div>
            </div>

            {isLoading ? (
              <div className="grid gap-6">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="aspect-[3/1] glass rounded-2xl animate-pulse-slow"
                       style={{ animationDelay: `${i * 100}ms` }} />
                ))}
              </div>
            ) : filteredProposals.length === 0 ? (
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500/20 via-pink-500/20 to-cyan-500/20 rounded-3xl blur-xl group-hover:blur-2xl transition-all"></div>
                <div className="relative glass rounded-3xl border border-white/5 p-20 text-center">
                  <div className="w-24 h-24 mx-auto mb-6 rounded-2xl bg-gradient-to-br from-purple-500/10 to-cyan-500/10 flex items-center justify-center backdrop-blur-xl">
                    {activeTab === "active" ? (
                      <FileText className="h-12 w-12 text-purple-400 animate-pulse" />
                    ) : (
                      <Archive className="h-12 w-12 text-cyan-400 animate-pulse" />
                    )}
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-3">
                    {activeTab === "active" ? "No Active Proposals" : "No Archived Proposals"}
                  </h3>
                  <p className="text-slate-400 max-w-md mx-auto">
                    {activeTab === "active"
                      ? "Check back later for new governance proposals"
                      : "Completed proposals will appear here"}
                  </p>
                </div>
              </div>
            ) : (
              <div className="grid gap-6">
                {filteredProposals.map((proposal, i) => (
                  <div key={proposal.id}
                       className="animate-fade-in-up"
                       style={{ animationDelay: `${i * 100}ms` }}>
                    <ProposalCard
                      proposal={proposal}
                      onVote={handleVote}
                      onTally={handleTally}
                      isVoting={votingProposalId === proposal.id}
                      isTallying={tallyingProposalId === proposal.id}
                      getVotePercentage={getVotePercentage}
                    />
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

// Proposal Card Component
interface ProposalCardProps {
  proposal: any;
  onVote: (proposalId: number, choice: "yes" | "no") => void;
  onTally: (proposalId: number) => void;
  isVoting: boolean;
  isTallying: boolean;
  getVotePercentage: (votes: number, total: number) => number;
}

function ProposalCard({ proposal, onVote, onTally, isVoting, isTallying, getVotePercentage }: ProposalCardProps) {
  const [timeLeft, setTimeLeft] = useState<string>("");
  const yesPercentage = getVotePercentage(proposal.yesVotes, proposal.totalVotes);
  const noPercentage = getVotePercentage(proposal.noVotes, proposal.totalVotes);

  // Update countdown timer
  useEffect(() => {
    if (!proposal.deadline) return;

    const updateTimer = () => {
      const now = Date.now();
      const remaining = proposal.deadline - now;

      if (remaining <= 0) {
        setTimeLeft("Ended");
        return;
      }

      const minutes = Math.floor(remaining / 60000);
      const seconds = Math.floor((remaining % 60000) / 1000);
      setTimeLeft(`${minutes}m ${seconds}s`);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);

    return () => clearInterval(interval);
  }, [proposal.deadline]);

  return (
    <Card className="glass glow-hover border border-white/5 overflow-hidden">
      <CardHeader className="p-6 pb-4">
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-2 flex-1">
            <div className="flex items-center gap-3">
              <h3 className="text-xl font-bold text-white">{proposal.title}</h3>
              <Badge className={`
                ${proposal.votingEnded
                  ? yesPercentage > noPercentage
                    ? 'bg-green-500/10 text-green-400 border-green-500/20'
                    : 'bg-red-500/10 text-red-400 border-red-500/20'
                  : 'bg-purple-500/10 text-purple-400 border-purple-500/20'
                }
              `}>
                {proposal.votingEnded
                  ? yesPercentage > noPercentage ? 'Passed' : 'Failed'
                  : 'Active'
                }
              </Badge>
            </div>
            <p className="text-sm text-slate-400">Proposal #{proposal.id}</p>
          </div>
        </div>
      </CardHeader>

      <CardContent className="p-6 pt-0 space-y-4">
        {proposal.body && (
          <p className="text-slate-300 leading-relaxed">{proposal.body}</p>
        )}

        {/* Voting Results */}
        <div className="space-y-3 pt-4">
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-400 flex items-center gap-2">
              <ThumbsUp className="h-4 w-4 text-green-400" />
              Yes
            </span>
            <span className="text-white font-semibold">
              {proposal.yesVotes} ({yesPercentage}%)
            </span>
          </div>
          <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-green-500 to-green-400 transition-all duration-500"
              style={{ width: `${yesPercentage}%` }}
            ></div>
          </div>

          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-400 flex items-center gap-2">
              <ThumbsDown className="h-4 w-4 text-red-400" />
              No
            </span>
            <span className="text-white font-semibold">
              {proposal.noVotes} ({noPercentage}%)
            </span>
          </div>
          <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-red-500 to-red-400 transition-all duration-500"
              style={{ width: `${noPercentage}%` }}
            ></div>
          </div>

          <p className="text-xs text-slate-500 pt-2">
            Total votes: {proposal.totalVotes}
          </p>
        </div>
      </CardContent>

      {!proposal.votingEnded && (
        <CardFooter className="p-6 pt-0">
          {/* Timer display */}
          {timeLeft && (
            <div className="w-full mb-3 flex items-center justify-center gap-2 text-sm text-slate-400">
              <Clock className="h-4 w-4" />
              <span>Time remaining: <span className="text-white font-semibold">{timeLeft}</span></span>
            </div>
          )}

          <div className="flex gap-3 w-full">
            <Button
              className="flex-1 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white"
              onClick={() => onVote(proposal.id, "yes")}
              disabled={isVoting}
            >
              {isVoting ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Voting...
                </>
              ) : (
                <>
                  <ThumbsUp className="mr-2 h-4 w-4" />
                  Vote Yes
                </>
              )}
            </Button>
            <Button
              className="flex-1 bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white"
              onClick={() => onVote(proposal.id, "no")}
              disabled={isVoting}
            >
              {isVoting ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Voting...
                </>
              ) : (
                <>
                  <ThumbsDown className="mr-2 h-4 w-4" />
                  Vote No
                </>
              )}
            </Button>
            <Button
              className="bg-gradient-to-r from-purple-500 to-cyan-500 hover:from-purple-600 hover:to-cyan-600 text-white px-4"
              onClick={() => onTally(proposal.id)}
              disabled={isTallying || timeLeft !== "Ended"}
              title={timeLeft !== "Ended" ? "Wait for voting period to end" : "Execute proposal"}
            >
              {isTallying ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Executing...
                </>
              ) : (
                <>
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Execute
                </>
              )}
            </Button>
          </div>
        </CardFooter>
      )}
    </Card>
  );
}

// Stat Badge Component
function StatBadge({ icon: Icon, value, label }: { icon: any; value: string | number; label: string }) {
  return (
    <div className="flex flex-col items-center gap-2 group cursor-default">
      <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-500/10 to-cyan-500/10 border border-white/5 flex items-center justify-center group-hover:scale-110 transition-transform">
        <Icon className="h-5 w-5 text-purple-400" />
      </div>
      <div className="text-center">
        <div className="text-2xl font-bold text-white">{value}</div>
        <div className="text-xs text-slate-500 uppercase tracking-wider">{label}</div>
      </div>
    </div>
  );
}
