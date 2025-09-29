import React, { useState } from 'react';
import { ChevronRight } from 'lucide-react';

const LogicBlenderUI = () => {
  const [activeScreen, setActiveScreen] = useState('menu');
  const [inputText, setInputText] = useState('');
  const [premises, setPremises] = useState([
    { text: 'P → Q', checked: false },
    { text: 'Q → R', checked: false },
    { text: 'P', checked: false }
  ]);

  const fruits = ['🍓', '🍌', '🍊', '🥑', '🍇', '🍐', '🍍', '🥝', '🍑', '🍋'];

  const addSymbol = (symbol) => {
    setInputText(prev => prev + symbol);
  };

  const clearInput = () => {
    setInputText('');
  };

  // Main Menu Screen
  const MainMenu = () => (
    <div className="relative w-full h-full bg-gradient-to-br from-pink-300 via-pink-200 to-orange-200 overflow-hidden">
      {/* Floating Fruits Background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {fruits.map((fruit, i) => (
          <div
            key={i}
            className="absolute text-4xl opacity-40"
            style={{
              left: `${(i * 11) % 90}%`,
              top: `${(i * 17) % 85}%`,
              transform: `rotate(${i * 15}deg)`,
              filter: 'drop-shadow(2px 2px 4px rgba(0,0,0,0.1))'
            }}
          >
            {fruit}
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center justify-center h-full px-6 py-8">
        {/* Logo Area */}
        <div className="text-center mb-8">
          <div className="text-6xl mb-3">🥤</div>
          <h1 className="text-4xl font-bold text-white mb-2" style={{
            textShadow: '3px 3px 0px rgba(139, 69, 19, 0.3), 2px 2px 8px rgba(0,0,0,0.2)'
          }}>
            Logic Blender
          </h1>
          <p className="text-sm text-brown-700 font-medium tracking-wide">
            Boolean Logic Learning Game
          </p>
        </div>

        {/* Menu Buttons */}
        <div className="w-full max-w-xs space-y-3">
          <MenuButton onClick={() => setActiveScreen('phase1')}>
            PLAY GAME
          </MenuButton>
          <MenuButton onClick={() => setActiveScreen('phase2')}>
            PROOF BUILDER
          </MenuButton>
          <MenuButton variant="secondary">
            DEBUG OPTIONS
          </MenuButton>
          <MenuButton variant="secondary">
            SETTINGS
          </MenuButton>
          <MenuButton variant="secondary">
            QUIT
          </MenuButton>
        </div>

        {/* Bottom Links */}
        <div className="mt-8 space-y-2 text-center">
          <button className="text-brown-700 font-semibold text-sm hover:text-brown-900 transition-colors block w-full">
            📊 Progress & Stats
          </button>
          <button className="text-brown-700 font-semibold text-sm hover:text-brown-900 transition-colors block w-full">
            🎯 Grid Menu
          </button>
        </div>
      </div>
    </div>
  );

  // Phase 1: Premise Building
  const Phase1Screen = () => (
    <div className="w-full h-full bg-gradient-to-b from-purple-50 to-blue-50 flex flex-col">
      {/* Top Bar */}
      <div className="bg-gradient-to-r from-purple-600 to-indigo-600 px-4 py-3 shadow-lg">
        <div className="flex justify-between items-center text-white text-sm font-semibold">
          <div className="flex items-center gap-1">
            <span className="text-lg">❤️</span>
            <span className="text-lg">❤️</span>
            <span className="text-lg">❤️</span>
          </div>
          <div className="text-base">Score: 1,250</div>
          <div className="text-base">LV.3</div>
        </div>
        {/* Timer Bar */}
        <div className="mt-2 h-2 bg-purple-900/30 rounded-full overflow-hidden">
          <div className="h-full w-3/4 bg-gradient-to-r from-green-400 via-yellow-400 to-red-400 rounded-full transition-all duration-300"></div>
        </div>
      </div>

      {/* Customer Area */}
      <div className="flex-1 flex items-start justify-center pt-6 px-4">
        <div className="relative">
          {/* Customer Character */}
          <div className="absolute -left-24 top-8">
            <div className="text-6xl">👨‍🍳</div>
          </div>
          
          {/* Speech Bubble */}
          <div className="bg-white rounded-2xl shadow-xl p-5 relative border-4 border-purple-300 max-w-sm">
            <div className="absolute -left-3 top-12 w-6 h-6 bg-white border-l-4 border-b-4 border-purple-300 transform rotate-45"></div>
            
            <h3 className="text-sm font-bold text-gray-700 mb-3">Premises to reconstruct:</h3>
            
            <div className="space-y-2 mb-4">
              {premises.map((premise, i) => (
                <div key={i} className="flex items-center gap-3">
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                    premise.checked ? 'bg-green-500 border-green-600' : 'bg-gray-100 border-gray-300'
                  }`}>
                    {premise.checked && <span className="text-white text-xs font-bold">✓</span>}
                  </div>
                  <span className={`font-mono text-base ${premise.checked ? 'text-gray-500' : 'text-gray-800'}`}>
                    {premise.text}
                  </span>
                </div>
              ))}
            </div>
            
            <div className="border-t-2 border-gray-200 pt-3 mt-3">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-red-600">TARGET:</span>
                <span className="text-lg font-mono font-bold text-red-600">R</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Input Area */}
      <div className="px-4 pb-4">
        <div className="bg-white rounded-xl shadow-lg p-4 border-2 border-purple-200">
          <label className="block text-xs font-bold text-gray-600 mb-2">Current Input:</label>
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="Type your premise here..."
            className="w-full px-3 py-2 border-2 border-gray-300 rounded-lg text-lg font-mono focus:border-purple-500 focus:outline-none"
          />
        </div>

        {/* Virtual Keyboard */}
        <div className="mt-4 space-y-2">
          <div className="flex justify-center gap-2">
            {['P', 'Q', 'R', 'S', 'T'].map(key => (
              <KeyButton key={key} onClick={() => addSymbol(key)} variant="variable">
                {key}
              </KeyButton>
            ))}
          </div>
          <div className="flex justify-center gap-2">
            {['∧', '⊕', '→', '∨'].map(key => (
              <KeyButton key={key} onClick={() => addSymbol(key)} variant="operator">
                {key}
              </KeyButton>
            ))}
          </div>
          <div className="flex justify-center gap-2">
            {['↔', '(', ')', '¬', '⌫'].map(key => (
              <KeyButton 
                key={key} 
                onClick={() => key === '⌫' ? setInputText(prev => prev.slice(0, -1)) : addSymbol(key)}
                variant={key === '⌫' ? 'delete' : key === '(' || key === ')' ? 'utility' : 'operator'}
              >
                {key}
              </KeyButton>
            ))}
          </div>
          
          <div className="flex gap-2 mt-4">
            <button
              onClick={clearInput}
              className="flex-1 bg-gradient-to-r from-red-500 to-red-600 text-white py-3 rounded-xl font-bold shadow-lg hover:shadow-xl transform hover:scale-105 transition-all"
            >
              CLEAR
            </button>
            <button
              className="flex-1 bg-gradient-to-r from-green-500 to-green-600 text-white py-3 rounded-xl font-bold shadow-lg hover:shadow-xl transform hover:scale-105 transition-all"
            >
              SUBMIT
            </button>
          </div>
        </div>
      </div>
    </div>
  );

  // Phase 2: Proof Builder
  const Phase2Screen = () => (
    <div className="w-full h-full bg-gradient-to-b from-slate-700 to-slate-800 flex flex-col text-white">
      {/* Header */}
      <div className="bg-gradient-to-r from-indigo-600 to-purple-600 px-4 py-3 shadow-lg">
        <h2 className="text-center font-bold text-lg">Phase 2: Proof Building</h2>
      </div>

      {/* Inventory Section */}
      <div className="px-4 py-3 bg-slate-800/50">
        <h3 className="text-sm font-bold text-gray-300 mb-2">Inventory</h3>
        <div className="bg-slate-900/50 rounded-lg p-3 min-h-20 border-2 border-slate-600">
          <p className="text-xs text-gray-400 italic">Available inference rules will appear here</p>
        </div>
      </div>

      {/* Target Section */}
      <div className="px-4 py-3">
        <div className="bg-slate-900/70 rounded-lg p-4 border-2 border-red-500/50">
          <h3 className="text-sm font-bold text-gray-300 mb-2">Target:</h3>
          <p className="text-2xl font-mono font-bold text-red-400">Prove: Q</p>
        </div>
      </div>

      {/* Rules Grid */}
      <div className="flex-1 px-4 overflow-y-auto">
        <div className="grid grid-cols-3 gap-2 mb-3">
          {['SIMP', 'CONJ', 'ADD', 'DM'].map(rule => (
            <RuleButton key={rule}>{rule}</RuleButton>
          ))}
        </div>
        <div className="grid grid-cols-4 gap-2 mb-3">
          {['DIST', 'COMM', 'ASSOC', 'IDEMP', '( )'].map(rule => (
            <RuleButton key={rule}>{rule}</RuleButton>
          ))}
        </div>
        <div className="grid grid-cols-3 gap-2">
          {['ABS', 'NEG', 'TAUT', 'CONTR', 'DNEG'].map(rule => (
            <RuleButton key={rule}>{rule}</RuleButton>
          ))}
        </div>
      </div>

      {/* Bottom Navigation */}
      <div className="p-4 bg-slate-900/50 border-t-2 border-slate-700">
        <button className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 text-white py-3 rounded-xl font-bold shadow-lg flex items-center justify-between px-4 hover:shadow-xl transform hover:scale-105 transition-all">
          <span>Single Operations</span>
          <ChevronRight size={20} />
        </button>
      </div>
    </div>
  );

  return (
    <div className="w-full max-w-md mx-auto bg-white" style={{ height: '812px' }}>
      {activeScreen === 'menu' && <MainMenu />}
      {activeScreen === 'phase1' && <Phase1Screen />}
      {activeScreen === 'phase2' && <Phase2Screen />}
      
      {/* Navigation for demo */}
      <div className="absolute top-2 left-2 flex gap-1 z-50">
        <button
          onClick={() => setActiveScreen('menu')}
          className="bg-black/50 text-white px-2 py-1 rounded text-xs font-bold"
        >
          Menu
        </button>
        <button
          onClick={() => setActiveScreen('phase1')}
          className="bg-black/50 text-white px-2 py-1 rounded text-xs font-bold"
        >
          Phase 1
        </button>
        <button
          onClick={() => setActiveScreen('phase2')}
          className="bg-black/50 text-white px-2 py-1 rounded text-xs font-bold"
        >
          Phase 2
        </button>
      </div>
    </div>
  );
};

// Reusable Components
const MenuButton = ({ children, onClick, variant = 'primary' }) => {
  const baseClasses = "w-full py-3 px-6 rounded-xl font-bold text-white shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-200";
  const variantClasses = variant === 'primary' 
    ? "bg-gradient-to-r from-brown-600 to-brown-700 hover:from-brown-700 hover:to-brown-800"
    : "bg-gradient-to-r from-brown-500 to-brown-600 hover:from-brown-600 hover:to-brown-700";
  
  return (
    <button onClick={onClick} className={`${baseClasses} ${variantClasses}`}>
      {children}
    </button>
  );
};

const KeyButton = ({ children, onClick, variant = 'variable' }) => {
  const variants = {
    variable: 'bg-gradient-to-br from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700',
    operator: 'bg-gradient-to-br from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700',
    utility: 'bg-gradient-to-br from-gray-500 to-gray-600 hover:from-gray-600 hover:to-gray-700',
    delete: 'bg-gradient-to-br from-red-500 to-red-600 hover:from-red-600 hover:to-red-700'
  };
  
  return (
    <button
      onClick={onClick}
      className={`w-12 h-12 rounded-lg font-bold text-white shadow-md hover:shadow-lg transform hover:scale-110 active:scale-95 transition-all ${variants[variant]}`}
    >
      {children}
    </button>
  );
};

const RuleButton = ({ children }) => (
  <button className="bg-slate-700 hover:bg-slate-600 border-2 border-slate-500 rounded-lg py-2 px-1 font-bold text-xs text-white shadow-md hover:shadow-lg transform hover:scale-105 transition-all">
    {children}
  </button>
);

export default LogicBlenderUI;
