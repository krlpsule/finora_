class FinanceQuote {
  final String text;
  final String author;
  final String category; // Opsiyonel: İleride filtreleme için kullanılabilir

  const FinanceQuote({
    required this.text, 
    required this.author,
    this.category = 'General',
  });
}

// Financial Motivation List
// Resources: BrainyQuote, Goodreads, Financial Blogs
final List<FinanceQuote> financeQuotes = [
  
  // --- Budgeting & Control ---
  FinanceQuote(
    text: "A budget is telling your money where to go instead of wondering where it went.",
    author: "Dave Ramsey",
    category: "Budgeting",
  ),
  FinanceQuote(
    text: "Don't tell me what you value, show me your budget, and I'll tell you what you value.",
    author: "Joe Biden",
    category: "Budgeting",
  ),
  FinanceQuote(
    text: "You must gain control over your money or the lack of it will forever control you.",
    author: "Dave Ramsey",
    category: "Control",
  ),
  FinanceQuote(
    text: "Balancing your money is the key to having enough.",
    author: "Elizabeth Warren",
    category: "Budgeting",
  ),
  FinanceQuote(
    text: "A budget tells us what we can't afford, but it doesn't keep us from buying it.",
    author: "William Feather",
    category: "Psychology",
  ),
  FinanceQuote(
    text: "It isn't what you earn but how spend it that fixes your class.",
    author: "Sinclair Lewis",
    category: "Lifestyle",
  ),
  
  // --- Saving & Spending ---
  FinanceQuote(
    text: "Do not save what is left after spending, but spend what is left after saving.",
    author: "Warren Buffett",
    category: "Saving",
  ),
  FinanceQuote(
    text: "Beware of little expenses. A small leak will sink a great ship.",
    author: "Benjamin Franklin",
    category: "Spending",
  ),
  FinanceQuote(
    text: "Money looks better in the bank than on your feet.",
    author: "Sophia Amoruso",
    category: "Modern",
  ),
  FinanceQuote(
    text: "Too many people spend money they haven't earned, to buy things they don't want, to impress people they don't like.",
    author: "Will Rogers",
    category: "Psychology",
  ),
  FinanceQuote(
    text: "Every time you borrow money, you're robbing your future self.",
    author: "Nathan W. Morris",
    category: "Debt",
  ),
  FinanceQuote(
    text: "He who buys what he does not need, steals from himself.",
    author: "Swedish Proverb",
    category: "Spending",
  ),
  FinanceQuote(
    text: "Rich people stay rich by living like they're broke. Poor people stay poor by living like they're rich.",
    author: "Unknown",
    category: "Lifestyle",
  ),
  FinanceQuote(
    text: "Just because you can afford it doesn't mean you should buy it.",
    author: "Suze Orman",
    category: "Spending",
  ),
  FinanceQuote(
    text: "Never spend your money before you have earned it.",
    author: "Thomas Jefferson",
    category: "Discipline",
  ),
  
  // --- YATIRIM & SERVET (Investing & Wealth) ---
  FinanceQuote(
    text: "The stock market is filled with individuals who know the price of everything, but the value of nothing.",
    author: "Philip Fisher",
    category: "Investing",
  ),
  FinanceQuote(
    text: "An investment in knowledge pays the best interest.",
    author: "Benjamin Franklin",
    category: "Growth",
  ),
  FinanceQuote(
    text: "Compound interest is the eighth wonder of the world. He who understands it, earns it... he who doesn't... pays it.",
    author: "Albert Einstein",
    category: "Investing",
  ),
  FinanceQuote(
    text: "The more your money works for you, the less you have to work for money.",
    author: "Idowu Koyenikan",
    category: "Passive Income",
  ),
  FinanceQuote(
    text: "Financial freedom is available to those who learn about it and work for it.",
    author: "Robert Kiyosaki",
    category: "Freedom",
  ),
  FinanceQuote(
    text: "Risk comes from not knowing what you're doing.",
    author: "Warren Buffett",
    category: "Knowledge",
  ),
  FinanceQuote(
    text: "If you don't find a way to make money while you sleep, you will work until you die.",
    author: "Warren Buffett",
    category: "Investing",
  ),
  FinanceQuote(
    text: "It's not how much money you make, but how much money you keep, how hard it works for you, and how many generations you keep it for.",
    author: "Robert Kiyosaki",
    category: "Wealth",
  ),
   FinanceQuote(
    text: "Formal education will make you a living; self-education will make you a fortune.",
    author: "Jim Rohn",
    category: "Growth",
  ),

  // --- MODERN ZİHNİYET & GENÇLER İÇİN (Modern Mindset) ---
  FinanceQuote(
    text: "Wealth consists not in having great possessions, but in having few wants.",
    author: "Epictetus",
    category: "Philosophy",
  ),
  FinanceQuote(
    text: "The goal isn't more money. The goal is living life on your terms.",
    author: "Chris Brogan",
    category: "Lifestyle",
  ),
  FinanceQuote(
    text: "Money is a terrible master but an excellent servant.",
    author: "P.T. Barnum",
    category: "Control",
  ),
  FinanceQuote(
    text: "Time is more valuable than money. You can get more money, but you cannot get more time.",
    author: "Jim Rohn",
    category: "Time",
  ),
  FinanceQuote(
    text: "You can make excuses and earn sympathy, or you can make money and earn admiration. The choice is always yours.",
    author: "Manoj Arora",
    category: "Motivation",
  ),
  FinanceQuote(
    text: "A big part of financial freedom is having your heart and mind free from worry about the what-ifs of life.",
    author: "Suze Orman",
    category: "Freedom",
  ),
  FinanceQuote(
    text: "Empty pockets never held anyone back. Only empty heads and empty hearts can do that.",
    author: "Norman Vincent Peale",
    category: "Motivation",
  ),
  FinanceQuote(
    text: "Wealth is the ability to fully experience life.",
    author: "Henry David Thoreau",
    category: "Philosophy",
  ),
  FinanceQuote(
    text: "Don't work for money; make it work for you.",
    author: "Robert Kiyosaki",
    category: "Investing",
  ),
  FinanceQuote(
    text: "The quickest way to double your money is to fold it over and put it back in your pocket.",
    author: "Will Rogers",
    category: "Humor",
  ),
  FinanceQuote(
    text: "Financial peace isn't the acquisition of stuff. It's learning to live on less than you make, so you can give money back and have money to invest.",
    author: "Dave Ramsey",
    category: "Peace",
  ),
  FinanceQuote(
    text: "Money is only a tool. It will take you wherever you wish, but it will not replace you as the driver.",
    author: "Ayn Rand",
    category: "Control",
  ),
  FinanceQuote(
    text: "If we command our wealth, we shall be rich and free. If our wealth commands us, we are poor indeed.",
    author: "Edmund Burke",
    category: "Control",
  ),
  FinanceQuote(
    text: "Being rich is having money; being wealthy is having time.",
    author: "Margaret Bonnano",
    category: "Wealth",
  ),
  FinanceQuote(
    text: "Debt erases freedom more surely than anything else.",
    author: "Merryn Somerset Webb",
    category: "Debt",
  ),
  FinanceQuote(
    text: "Opportunities don't happen. You create them.",
    author: "Chris Grosser",
    category: "Motivation",
  ),
  FinanceQuote(
    text: "Money often costs too much.",
    author: "Ralph Waldo Emerson",
    category: "Philosophy",
  ),
  FinanceQuote(
    text: "The only place where success comes before work is in the dictionary.",
    author: "Vidal Sassoon",
    category: "Work",
  ),
];
