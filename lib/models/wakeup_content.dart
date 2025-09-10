import 'user_profile.dart';

class WakeupContent {
  final Map<ZodiacSign, List<String>> horoscopes;
  final List<String> motivationalPhrases;
  final List<String> morningGreetings;

  WakeupContent({
    required this.horoscopes,
    required this.motivationalPhrases,
    required this.morningGreetings,
  });

  String getHoroscope(ZodiacSign sign) {
    final signHoroscopes = horoscopes[sign] ?? [];
    if (signHoroscopes.isEmpty) return 'Today is full of possibilities!';

    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return signHoroscopes[dayOfYear % signHoroscopes.length];
  }

  String getMotivationalPhrase() {
    if (motivationalPhrases.isEmpty)
      return 'Today is a beautiful day to chase your dreams!';

    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return motivationalPhrases[dayOfYear % motivationalPhrases.length];
  }

  String getMorningGreeting(String name) {
    if (morningGreetings.isEmpty) return 'Good morning, $name!';

    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final greeting = morningGreetings[dayOfYear % morningGreetings.length];
    return greeting.replaceAll('{name}', name);
  }
}

class ContentData {
  static WakeupContent get englishContent => WakeupContent(
        horoscopes: {
          ZodiacSign.aries: [
            'Your fiery spirit will guide you to amazing achievements today!',
            'Take charge of your day with confidence and determination!',
            'New opportunities are heading your way - embrace them boldly!',
            'Your leadership skills will shine bright today!',
            'Adventure and excitement await you today!',
          ],
          ZodiacSign.taurus: [
            'Stability and comfort surround you today - enjoy the simple pleasures!',
            'Your patience and persistence will pay off beautifully!',
            'Focus on what truly matters and find peace in the moment!',
            'Your practical wisdom will help others today!',
            'Take time to appreciate the beauty around you!',
          ],
          ZodiacSign.gemini: [
            'Your curiosity will lead to fascinating discoveries today!',
            'Communication flows effortlessly - share your brilliant ideas!',
            'Variety and change bring exciting energy to your day!',
            'Your adaptability is your greatest strength today!',
            'Connect with others and spread your infectious enthusiasm!',
          ],
          ZodiacSign.cancer: [
            'Trust your intuition - it will guide you perfectly today!',
            'Your caring nature brings comfort to those around you!',
            'Home and family connections provide deep satisfaction today!',
            'Your emotional intelligence shines brightly!',
            'Nurture your dreams - they are closer than you think!',
          ],
          ZodiacSign.leo: [
            'Your natural charisma lights up every room you enter!',
            'Creative expression brings you joy and recognition today!',
            'Your generous heart touches everyone you meet!',
            'Confidence and warmth are your superpowers today!',
            'Shine bright and inspire others with your radiant energy!',
          ],
          ZodiacSign.virgo: [
            'Your attention to detail creates something truly beautiful today!',
            'Organization and planning set you up for success!',
            'Your helpful nature makes a real difference in someone\'s life!',
            'Perfection isn\'t needed - your best effort is enough!',
            'Your analytical mind solves problems with ease!',
          ],
          ZodiacSign.libra: [
            'Balance and harmony flow naturally through your day!',
            'Your diplomatic skills bring peace to challenging situations!',
            'Beauty and art inspire your creative soul today!',
            'Relationships flourish under your caring attention!',
            'Your sense of justice makes the world a better place!',
          ],
          ZodiacSign.scorpio: [
            'Your intense passion drives you toward your deepest goals!',
            'Transformation and growth are your themes today!',
            'Your mysterious charm draws interesting people to you!',
            'Trust your powerful instincts - they never lie!',
            'Your determination can move mountains today!',
          ],
          ZodiacSign.sagittarius: [
            'Adventure calls your name - follow where it leads!',
            'Your optimism spreads like sunshine to everyone around you!',
            'Wisdom comes through new experiences and perspectives!',
            'Your free spirit inspires others to dream bigger!',
            'The world is your classroom today - learn something amazing!',
          ],
          ZodiacSign.capricorn: [
            'Your steady climb toward success continues with determination!',
            'Responsibility and achievement go hand in hand today!',
            'Your practical approach turns dreams into reality!',
            'Leadership comes naturally - others look up to you!',
            'Every step forward, no matter how small, matters!',
          ],
          ZodiacSign.aquarius: [
            'Your unique perspective brings innovation to everything you touch!',
            'Humanitarian causes capture your heart and energy today!',
            'Think outside the box - your ideas could change everything!',
            'Your independence and originality are truly inspiring!',
            'Technology and progress align with your forward-thinking mind!',
          ],
          ZodiacSign.pisces: [
            'Your intuitive gifts reveal hidden truths and beauty today!',
            'Compassion flows from your heart like a healing river!',
            'Dreams and imagination open new worlds of possibility!',
            'Your artistic soul creates magic wherever you go!',
            'Trust in the flow of life - it carries you toward your destiny!',
          ],
        },
        motivationalPhrases: [
          'Today is your canvas - paint it with bold, beautiful strokes!',
          'Every sunrise brings new possibilities - embrace them all!',
          'Your potential is limitless - let it shine today!',
          'Small steps forward still move you closer to your dreams!',
          'Believe in yourself as much as we believe in you!',
          'Today is the perfect day to start something amazing!',
          'Your positive energy can change someone\'s entire day!',
          'Challenges are just opportunities wearing disguises!',
          'You have everything within you to make today incredible!',
          'Your smile is your superpower - use it generously today!',
          'Every moment is a fresh start waiting to happen!',
          'Your kindness creates ripples of joy everywhere you go!',
          'Today\'s accomplishments are tomorrow\'s fond memories!',
          'You are stronger than any challenge that comes your way!',
          'Let your light shine so bright that others find their way!',
        ],
        morningGreetings: [
          'Good morning, {name}! Today holds wonderful surprises just for you!',
          'Rise and shine, {name}! The world is ready for your amazing energy!',
          'Hello beautiful {name}! It\'s time to make today absolutely fantastic!',
          'Wake up, {name}! Adventure and joy are waiting for you!',
          'Good morning, {name}! Your dreams are calling - time to answer!',
          'Hey there, {name}! Today is your day to shine brilliantly!',
          'Morning, {name}! Let\'s make today better than yesterday!',
          'Wake up, sunshine {name}! The world needs your special magic today!',
          'Good morning, {name}! Today is full of endless possibilities!',
          'Hello {name}! Time to wake up and embrace all the amazing things ahead!',
          'Rise up, {name}! Today is your chance to make a difference!',
          'Good morning, {name}! Let your positive energy light up the world!',
        ],
      );

  static WakeupContent get spanishContent => WakeupContent(
        horoscopes: {
          ZodiacSign.aries: [
            '¡Tu espíritu ardiente te guiará hacia logros increíbles hoy!',
            '¡Toma el control de tu día con confianza y determinación!',
            '¡Nuevas oportunidades se dirigen hacia ti - abrázalas con valentía!',
            '¡Tus habilidades de liderazgo brillarán intensamente hoy!',
            '¡La aventura y la emoción te esperan hoy!',
          ],
          ZodiacSign.taurus: [
            '¡La estabilidad y comodidad te rodean hoy - disfruta los placeres simples!',
            '¡Tu paciencia y persistencia serán recompensadas hermosamente!',
            '¡Concéntrate en lo que realmente importa y encuentra paz en el momento!',
            '¡Tu sabiduría práctica ayudará a otros hoy!',
            '¡Tómate tiempo para apreciar la belleza a tu alrededor!',
          ],
          ZodiacSign.gemini: [
            '¡Tu curiosidad te llevará a descubrimientos fascinantes hoy!',
            '¡La comunicación fluye sin esfuerzo - comparte tus ideas brillantes!',
            '¡La variedad y el cambio traen energía emocionante a tu día!',
            '¡Tu adaptabilidad es tu mayor fortaleza hoy!',
            '¡Conéctate con otros y comparte tu entusiasmo contagioso!',
          ],
          ZodiacSign.cancer: [
            '¡Confía en tu intuición - te guiará perfectamente hoy!',
            '¡Tu naturaleza cariñosa trae consuelo a quienes te rodean!',
            '¡Las conexiones del hogar y la familia brindan satisfacción profunda hoy!',
            '¡Tu inteligencia emocional brilla intensamente!',
            '¡Nutre tus sueños - están más cerca de lo que piensas!',
          ],
          ZodiacSign.leo: [
            '¡Tu carisma natural ilumina cada habitación en la que entras!',
            '¡La expresión creativa te trae alegría y reconocimiento hoy!',
            '¡Tu corazón generoso toca a todos los que conoces!',
            '¡La confianza y la calidez son tus superpoderes hoy!',
            '¡Brilla intensamente e inspira a otros con tu energía radiante!',
          ],
          ZodiacSign.virgo: [
            '¡Tu atención al detalle crea algo verdaderamente hermoso hoy!',
            '¡La organización y planificación te preparan para el éxito!',
            '¡Tu naturaleza servicial hace una diferencia real en la vida de alguien!',
            '¡No se necesita perfección - tu mejor esfuerzo es suficiente!',
            '¡Tu mente analítica resuelve problemas con facilidad!',
          ],
          ZodiacSign.libra: [
            '¡El equilibrio y la armonía fluyen naturalmente a través de tu día!',
            '¡Tus habilidades diplomáticas traen paz a situaciones desafiantes!',
            '¡La belleza y el arte inspiran tu alma creativa hoy!',
            '¡Las relaciones florecen bajo tu atención cariñosa!',
            '¡Tu sentido de justicia hace del mundo un lugar mejor!',
          ],
          ZodiacSign.scorpio: [
            '¡Tu pasión intensa te impulsa hacia tus metas más profundas!',
            '¡La transformación y el crecimiento son tus temas hoy!',
            '¡Tu encanto misterioso atrae personas interesantes hacia ti!',
            '¡Confía en tus poderosos instintos - nunca mienten!',
            '¡Tu determinación puede mover montañas hoy!',
          ],
          ZodiacSign.sagittarius: [
            '¡La aventura llama tu nombre - sigue hacia donde te lleva!',
            '¡Tu optimismo se extiende como el sol a todos a tu alrededor!',
            '¡La sabiduría viene a través de nuevas experiencias y perspectivas!',
            '¡Tu espíritu libre inspira a otros a soñar más grande!',
            '¡El mundo es tu aula hoy - aprende algo increíble!',
          ],
          ZodiacSign.capricorn: [
            '¡Tu ascenso constante hacia el éxito continúa con determinación!',
            '¡La responsabilidad y el logro van de la mano hoy!',
            '¡Tu enfoque práctico convierte los sueños en realidad!',
            '¡El liderazgo te viene naturalmente - otros te admiran!',
            '¡Cada paso adelante, sin importar cuán pequeño, importa!',
          ],
          ZodiacSign.aquarius: [
            '¡Tu perspectiva única trae innovación a todo lo que tocas!',
            '¡Las causas humanitarias capturan tu corazón y energía hoy!',
            '¡Piensa fuera de lo común - tus ideas podrían cambiar todo!',
            '¡Tu independencia y originalidad son verdaderamente inspiradoras!',
            '¡La tecnología y el progreso se alinean con tu mente visionaria!',
          ],
          ZodiacSign.pisces: [
            '¡Tus dones intuitivos revelan verdades ocultas y belleza hoy!',
            '¡La compasión fluye de tu corazón como un río sanador!',
            '¡Los sueños y la imaginación abren nuevos mundos de posibilidad!',
            '¡Tu alma artística crea magia dondequiera que vas!',
            '¡Confía en el flujo de la vida - te lleva hacia tu destino!',
          ],
        },
        motivationalPhrases: [
          '¡Hoy es tu lienzo - píntalo con trazos audaces y hermosos!',
          '¡Cada amanecer trae nuevas posibilidades - abrázalas todas!',
          '¡Tu potencial es ilimitado - déjalo brillar hoy!',
          '¡Los pequeños pasos hacia adelante aún te acercan a tus sueños!',
          '¡Cree en ti mismo tanto como nosotros creemos en ti!',
          '¡Hoy es el día perfecto para comenzar algo increíble!',
          '¡Tu energía positiva puede cambiar el día completo de alguien!',
          '¡Los desafíos son solo oportunidades disfrazadas!',
          '¡Tienes todo dentro de ti para hacer hoy increíble!',
          '¡Tu sonrisa es tu superpoder - úsala generosamente hoy!',
          '¡Cada momento es un nuevo comienzo esperando suceder!',
          '¡Tu bondad crea ondas de alegría dondequiera que vas!',
          '¡Los logros de hoy son los recuerdos queridos de mañana!',
          '¡Eres más fuerte que cualquier desafío que se cruce en tu camino!',
          '¡Deja que tu luz brille tan intensamente que otros encuentren su camino!',
        ],
        morningGreetings: [
          '¡Buenos días, {name}! ¡Hoy guarda sorpresas maravillosas solo para ti!',
          '¡Levántate y brilla, {name}! ¡El mundo está listo para tu energía increíble!',
          '¡Hola hermoso/a {name}! ¡Es hora de hacer hoy absolutamente fantástico!',
          '¡Despierta, {name}! ¡La aventura y la alegría te están esperando!',
          '¡Buenos días, {name}! ¡Tus sueños están llamando - es hora de responder!',
          '¡Hola, {name}! ¡Hoy es tu día para brillar magnificamente!',
          '¡Buenos días, {name}! ¡Hagamos hoy mejor que ayer!',
          '¡Despierta, sol {name}! ¡El mundo necesita tu magia especial hoy!',
          '¡Buenos días, {name}! ¡Hoy está lleno de posibilidades infinitas!',
          '¡Hola {name}! ¡Es hora de despertar y abrazar todas las cosas increíbles que vienen!',
          '¡Levántate, {name}! ¡Hoy es tu oportunidad de marcar la diferencia!',
          '¡Buenos días, {name}! ¡Deja que tu energía positiva ilumine el mundo!',
        ],
      );
}
