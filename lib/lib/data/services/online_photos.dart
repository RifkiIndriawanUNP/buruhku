// Kumpulan URL foto bertema Indonesia / aktivitas sehari-hari.
// Foto dipetakan per JUDUL jasa agar tidak tertukar dengan kategori lain.
// Avatar agen dan reviewer menggunakan foto artis Indonesia (Genap = Cowok, Ganjil = Cewek).

class OnlinePhotos {
  // ---- 1. Foto Profil Agen (36 Foto: Genap = Cowok, Ganjil = Cewek) ----
  static const List<String> agentAvatars = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTmw5DfuycjApAB4j3Dxjjo_GxnfBjWVyzlExg7gtYzobGSUI3naRM5jszg&s', // [0] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSKpoIKrlcL15tuDeGQh8vcoFcUgLmTGv4iWRv4Md7V4A&s=10', // [1] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZ1uN-dW_OeD2cxPO8coeMLz55o-7cYBWOWKqtj-wupHkuQmVyj7fJXyZB&s', // [2] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRgRcIQGsGIT4os-U1r9ll_9AyDzwhl4RjbJT6i68V7OA&s=10', // [3] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSYdKNUwFEY1V7aSJ8FWVkf5qs1wIk3KIjGk4xlfhkUwFhBYPik3v1sG3mm&s', // [4] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxbOanPsRROejt-oLEXEhgr3-_NL-u5hJ7klghUHDpWA&s=10', // [5] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9aiGeFm-SeSo-JtnN09X3ksb5EgObyz67aRkCk3oRe02DjJ4wz8i_yxg3&s', // [6] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQXWv7pn5nyVPMcr9WBtnrYLYwyaR9ibUfznOXYtAPKhg&s=10', // [7] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRp9VJCPMNkqg2HMjKNE3_knJhKsmoBoNedbhcebFoC-A&s=10', // [8] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROyzd9Ak9gUpf_KKfY2jDCKvM0DQHesEBlnszDYRQfeg&s=10', // [9] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRAzk90F3f4pXJIpjDhz_M4kbmV_GUE8e7Fab3tzIs28Q&s=10', // [10] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSurSk18G43oAWNmOfKK8T5sG4gV8ot7LuPMeJKNNWaBg&s=10', // [11] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSTNMa55aY3UbhytpxjspC5c9ko7bIn0lkRIXhTavLwxw&s=10', // [12] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS5qOSwXVUCll9y1me7OEW9T3cwF36WFEdjakwUlivqKw&s=10', // [13] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPiXV24EA3PRcFCjdsg8FKeM42gXYYSsLTOwz86TuxaA&s=10', // [14] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwcJoHn-WEI67h7NHbNDC65aLFtglSF-rfHRGoZd_XFQ&s=10', // [15] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJp2z6PRgKJvw2wY0ko8AJV4aQq-iWyAh8XX10aBzV5g&s=10', // [16] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREOpRBdDkiS0mYCggehtj37gMNNPXA69Vt57lVq_KrNw&s=10', // [17] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_jF52B0KfMrtZhvPApzlID_Bh8Bt2OOcSnuXp_FdXUg&s=10', // [18] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTb-MmZPRjeRzNbXN4ADwZ1cM-Ou_w7vjvbd4ykuaE_Vg&s=10', // [19] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTj6KXjopaQJwW6QDX4_6GOdsLTVdKpnJjHOxi0DTWqtg&s=10', // [20] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQ5dfewkZzWe6opEVt6oa0_VsVcEaN386aWUqS6QXO4A&s=10', // [21] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSl8YCe7tgBI8N-Krmqj3CHuiK5TUX4WIUZYwUrCxuk-A&s=10', // [22] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPe4XxAHtPMqQi33NMxMv461ooXACOJ1_jUP1QCAf3XQ&s=10', // [23] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR3HLttqhTaYKk74-w-C7g6GDcAWEyiOcESrYUY4mHjpg&s=10', // [24] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTJItllyhr1nCGOrX-bDlPDKo8Tmy2uAgAoik5UYo0U_A&s', // [25] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQU14jgZ4ofTlJu9ZVscHTwXrsHi8ZySiHDlFQtRk39tg&s=10', // [26] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPxp8bwap9B1gzORWbOmry_1oBlxPWmmxyrRoQMQ6cCA&s=10', // [27] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSO9_PPlNlnixhJK2Jxp3K9p_s1oPYi1japRkg9CNyzOA&s=10', // [28] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRjQwJjL5pmYshguAEOoIRPF2o4lD-nn1h1SNkLyoqNuQ&s=10', // [29] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTVvgq8cLD8XLoVkR3S4UNJ6fUvn8AKVcGXURNBx6w18Q&s=10', // [30] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXliZL2jeArwnxIazoaLAOhA9XCxur97Zr9L6GyC6g7w&s=10', // [31] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRjHj1efR6h8j_Y6okAc209Y7JeE5tukDILYDOn7u2fJw&s=10', // [32] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTbb8vehQf4pRaN3Cyh3k96Qu11zA-qr_qjmSpvWd7Q6Q&s=10', // [33] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4Cs52uoynLC-wHJzvt3mDq1i5uOZeHvefBRKjpoiPbg&s=10', // [34] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQp-lJFxZss7Dqt3-xx17A9jAUUHDisYwzukut_1nMk4w&s=10', // [35] Cewek
  ];

  static String agentAvatar(int index) =>
      agentAvatars[index % agentAvatars.length];

  /// Helper tambahan jika ingin mengambil avatar agen spesifik berdasarkan gender
  static String agentAvatarByGender(int index, {required bool isFemale}) {
    final baseIndex = (index * 2) + (isFemale ? 1 : 0);
    return agentAvatars[baseIndex % agentAvatars.length];
  }

  // ---- 2. Foto per JUDUL jasa ----
  // Kunci harus SAMA PERSIS dengan judul di catSuggest / templates.
  static const Map<String, List<String>> titlePhotos = {
    // ===== CLEAN =====
    'Bersihkan rumah': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT7SSCiuPK9ksfJYTny4ibBP3r-C5sDp03Y6KUivrVeQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTFbISbU-NLq5G3loRsjSB6SopEmsVThYS4wlp14baIMw&s=10',
    ],
    'Sapu halaman': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeGlsXNoj1kzGT5zBfONmg2i2obr3d_3d4oVLTtv2XWw&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ5v455oUDszYtQjhFew-RGfxABQisD4AH-dOEiAubCcw&s=10',
    ],
    'Ngepel teras dan lantai': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQa6fzNG4X8-DdLT6iUQ2T-HvpUZmsAATfczjDHE2r2rg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSS5r2_eV52wCfDAc-KvANe13Jlu8kzOrvlwDsDIht6RQ&s=10',
    ],
    'Bersihkan kaca dan jendela': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHxH_ybRNtWrADQTvyuCy3TAUdOM1M4Mmi69OnBVw3_g&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnIFJIeru5jIeEV7qGWKqpAO59AotiMuMoPLDkFX5fVw&s=10',
    ],
    'Bersihkan kamar mandi': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbq5kY0xEXXg837TMkUri-05-sadB29l4bcc7OvZQT_A&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvGW87pvKrGr9-FH-M_BxGZfMTIk0w2h1z4Kdd-ibbdg&s=10',
    ],

    // ===== ELEC =====
    'Pasang kipas angin': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4t7NMhe1FnDdATiXpJ55sPy24Qzl5xYsZlMaPpVyiTg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQjwp7iHC_dImEX8GWOeTS6mejmVxGqiZqj07EwgQapOw&s=10',
    ],
    'Ganti lampu dan fitting': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjpx4kzfIT6cgZXmeC6BHZlo4rcntU794SE67Q2nrYMA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQV87-SgI4xDLkFkoygEjF4lSNWITWBV4S2YfhYsGpAYA&s=10',
    ],
    'Pasang stop kontak': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPffxX5LiuYMI0i-TuksairKAOVT92jz7Uay-j9RvF7g&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSJhChf3wBEHn1WqmKvzDRn0-HkimQpCWI9BUxGFsS_MA&s=10',
    ],
    'Cek kulkas atau mesin cuci': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQEFKs4ktov1jRex_1L7Pv9AvUu4z_4GFcw70rIXAooiA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgecPa-1zWXNrZ9_cDiGF79Ph0gfGAjKkQlcerUKSyTw&s=10',
    ],
    'Pasang TV di dinding': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQF-VZBqYPpNiLbeiyLysObMZJeMo5J79d92HdwjkrwFA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTo2Ffyn1uRoT25eZR04FkJejuh3e5I0ArsNDONVFaEMA&s=10',
    ],

    // ===== MOVE =====
    'Angkat barang': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRZwtzMtx0oiJuOxMOBaWrZxiYgdHHv6MgN8VvMdMWMlQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ2AV2vvxSVevFBy-oQN0OjpqKNFf_jr-rLw8IQqApgng&s=10',
    ],
    'Bantu pindahan rumah': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy0wpVr-1DkG2ug9eHaPKX5Qj0BqHO0hMG0wzOoH0nSQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRFnJzXGFEMj7pvrGSY0ZW4oT2D4aRNg3vHm7a8TSdChQ&s=10',
    ],
    'Angkat galon dan gas': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeYXLPEr3QvqNfxlPuOviAjdW6Btt4V7PTj6cyu2cSpg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSm3XdlMsGZnWThsQM0VWDVWi7qCroCrslryaBmoOy-Lg&s=10',
    ],
    'Bongkar muat barang': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSpuDcCYSrMd8Mv00COhf6WifU9xMXdCiV4BpDtBdJeVQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS0VpVMYDsVDBpZGLMKF3xt4uPWXdx3m_lg_Gw98U8TDQ&s=10',
    ],
    'Pindah kasur dan lemari': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQT04nEFSdfcfaMHEh_gaBaPiWStuJguHCJnGM2Wjhjsg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyufUYO4lvtWUyrF3PjI4xsuJYuITTNW_cCN-MLkulFQ&s=10',
    ],

    // ===== GARDEN =====
    'Bersihkan halaman': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRw-NJ1MPXgfj9bup2meu4UGu1gzkWL_-a7R0oIqvHJA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTIrTVKfXpxz_EdjwZKO9G8FNRqMmiPUkS6vu--Bo-xEg&s=10',
    ],
    'Pangkas rumput': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTRTPaxJqHeBvtse89BN70BIxPXi9msFEssiyErWQA98A&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRNHM6KsWkKZBeCxD9HR2qXEGOjFfvIbv2-Vr02Nv6TMQ&s=10',
    ],
    'Pangkas pagar tanaman': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTPBRMcCMtFMjAW3Q7nhwMitHFCRBTAS9fbEbLIzegIrA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZJPklYwTqN7YwpYFVo5tXXP0NcLlOSbEAq4N4wgyquQ&s=10',
    ],
    'Tanam dan pindah tanaman': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ76t_lDzUob2xtzi2mnyghW6aFKu1o-nEh5vX3B8Bopg&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTUg13iN1WUtwXVjEaaXhrYjm5y9VfA_snCD_HLm9hrNA&s=10',
    ],
    'Siram dan rawat tanaman': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSTjdOny7I4yTebbKBktAiV_1iZmR4J6uO2xRh4JcWQDg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTB60TZ0xN0BoMO-0O6W76pn5VruL-hc3FdN29-_wZvZw&s=10',
    ],

    // ===== REPAIR =====
    'Benerin genteng bocor': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQQIv9UB4khr5RoWzbO0eVn_u3LFhdXE5vFdrt7gPXjA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSPYBslfvVBXVO7R3NXwSIpXYH-RXxkmgO3vOmdWMN2ag&s=10',
    ],
    'Cat dinding': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTGgT_tz9-btaM2RM-GH9RYImKILTG__SkMWc7Ny2cYUg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbhzl3hhIYPlZTOj8EkfkQVeQBcwOeMFaDLtC99lNE8g&s=10',
    ],
    'Perbaiki pintu dan engsel': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTvy0WYG6eDkDUX5QbPNMlilM8F44ozs_yHQNUP333jUQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSEGMBLv7GFQq1WRVL580ca-2oBcvIZn2-AVfR4PBzzeg&s=10',
    ],
    'Tambal plafon bocor': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgXIOoRsAR4hNhoRJCvEHB1osSNsGgoqIEscewdHs9sg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRWcgDiPS59fJBdZhg5qLcngBQ1W-tRQcS4mS22ssGH1Q&s=10',
    ],
    'Perbaiki keran dan saluran': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSIkzfar_H9U8M1p6UFQ7w9LM-l8cL21hJX4CejoLlnNQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpXr9HebuM5jzFGT2ZtAKqynOvUo28k8qqj87jYmAXCg&s=10',
    ],

    // ===== ERRAND =====
    'Titip belikan makanan': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTfP5McC-GT0_TO3YzmrSbFXnwMTmf8AAq3r9JQ5DTLKA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSPWaOaKak6BuOv4zuEmBfhAa0dIuVFuCETxfheijEGZw&s=10',
    ],
    'Antar paket': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSevHnVrJ2ozaOD8Fd9CZFTo3-lYMfs_9UBdH-Z0CcqAA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpnA6S7Fh6khmnnDjwg92P0ytE6ojnrPLw0kKfsQmzYQ&s=10',
    ],
    'Belikan galon dan gas': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTkPIg3lmh_kDAFMK2w9kdmKi5oMsFACxKyx0m8ZWdpBg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNkUQdlnjYjDf1ygbgEGpZJziorsCxzmh2GNSzbmP80w&s=10',
    ],
    'Antre dan urus berkas': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQIPhvRCW3B0zmTpizSwgNbcnht-ub9R7oEuCI9biXWMQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQDu8OFIKH7EHJNdWk7SRdBUDCle76f3NtdR6iMlWxL-g&s=10',
    ],
    'Ambil pesanan di toko': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT-dprmg7VlQJj29e_olzPTpG3MbB8SkS75Jw&s=18',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLfx6cmo1T88zlgvjrHkVeVeuoXAMttJ7j6piYtmKJKQ&s',
    ],

    // ===== LAUNDRY =====
    'Nyetrika baju': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRDrmTaEY_vS1A5e4JlF4pmObE8Byu9Tm622N6MOB41Gw&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbZMA4NFPXOlkK4J1OrwCLMIH06ZQtzUXqh3MdE8YeNQ&s=10',
    ],
    'Cuci dan jemur baju': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQUrhYRkLQn6k9yTo-SR3zV4R_fBU444sGPvqQ2tlJMNA&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6BsOEWc7oknGA4_Xttd1PtjBBUthy91mRUYYkOn1yxw&s=10',
    ],
    'Lipat dan susun baju': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ03iIxshHMVj51MyIYT5f0ga_koCw1zHtq9oCH7Mk6sg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRruB3iUQVlgYmJFCh82zahTq-7LDEEFRQecO3b0l_FsQ&s=10',
    ],
    'Cuci karpet atau sprei': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXsruJEb1p1oAV9XT1A-0Tiw5C6WBnjAf2i-s0LwXY7Q&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRb7hsfpDXRJuSQUQEeGZAwjeVNGvbCQHFV0e30L7Dr4w&s=10',
    ],
    'Setrika seragam sekolah': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRFC70bMNukznlSxOQuFFTYediC9uXBX_yPSzPF22CqIQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQaejfvMglxLOkLOLmsin8v_DkHeZVR-weOn7DrPFjf4g&s=10',
    ],

    // ===== OTHER =====
    'Bantu atur gudang': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTfryca8oAgYVpKKEfLmbRFDXILmN7shtgq2Jdz1YCM-A&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFRyxsSl1YofX6bt9eSq4CD37IRKc6lAPqmKl7OswBrA&s=10',
    ],
    'Jaga stand atau toko': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTqYxCM23PbbK1h1BpQoyiBCUePANzHAlmn6MLrRrtiwg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWRbu_t2FkbsBXQD8eKAkHA2aQN4UPdzaLvmRw7qdUxQ&s=10',
    ],
    'Bantu acara keluarga': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqPTsyIfhgM3eesxSzgwF-0CnZdia0Ub3ADz2IcTtWAg&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQPfmdtN5J1779nwPaluxjSKBxMeIH9QZaGReFOzylU1Q&s=10',
    ],
    'Bantu masak dan cuci piring': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSWorTeNr9hBuZGnVnXKzyUkWcuRhwDezMfx-2b-kMkmQ&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRQGOblojO3sp-QNv-R1K5NYdMn4kFXfcxKlKkEdlbsyw&s=10',
    ],
    'Tenaga serabutan harian': [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQhybtyJAJfilVYmUmB13k6tDy74l0Refn6YP98yIIWww&s=10',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTw9SvnqTCHhLmLWAoixJI_CHg4_rZY9qVYCSzaek_rdg&s=10',
    ],
  };

  /// Ambil 1 foto sesuai judul.
  static String photoForTitle(String cat, String title, int index) {
    final list = titlePhotos[title] ?? categoryPhotos[cat] ?? categoryPhotos['other']!;
    return list[index % list.length];
  }

  /// Ambil galeri foto sesuai judul.
  static List<String> photosForTitle(String cat, String title) =>
      List<String>.from(titlePhotos[title] ?? categoryPhotos[cat] ?? categoryPhotos['other']!);

  // ---- 3. Fallback per kategori (tetap dipertahankan) ----
  static const Map<String, List<String>> categoryPhotos = {
    'clean': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT7SSCiuPK9ksfJYTny4ibBP3r-C5sDp03Y6KUivrVeQ&s=10'],
    'elec': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4t7NMhe1FnDdATiXpJ55sPy24Qzl5xYsZlMaPpVyiTg&s=10'],
    'repair': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQQQIv9UB4khr5RoWzbO0eVn_u3LFhdXE5vFdrt7gPXjA&s=10'],
    'garden': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRw-NJ1MPXgfj9bup2meu4UGu1gzkWL_-a7R0oIqvHJA&s=10'],
    'move': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQy0wpVr-1DkG2ug9eHaPKX5Qj0BqHO0hMG0wzOoH0nSQ&s=10'],
    'laundry': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRDrmTaEY_vS1A5e4JlF4pmObE8Byu9Tm622N6MOB41Gw&s=10'],
    'errand': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSevHnVrJ2ozaOD8Fd9CZFTo3-lYMfs_9UBdH-Z0CcqAA&s=10'],
    'other': ['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTfryca8oAgYVpKKEfLmbRFDXILmN7shtgq2Jdz1YCM-A&s=10'],
  };

  static String servicePhoto(String cat, int index) {
    final list = categoryPhotos[cat] ?? categoryPhotos['other']!;
    return list[index % list.length];
  }

  static List<String> servicePhotos(String cat) =>
      List<String>.from(categoryPhotos[cat] ?? categoryPhotos['other']!);

  static List<String> portfolioForCats(List<String> cats) {
    final res = <String>[];
    for (final c in cats) {
      final list = categoryPhotos[c];
      if (list != null) res.addAll(list);
    }
    if (res.isEmpty) res.addAll(categoryPhotos['other']!);
    return res.take(3).toList();
  }

  // ---- 4. Bukti hasil kerja ----
  static const List<String> proofPhotos = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTGgT_tz9-btaM2RM-GH9RYImKILTG__SkMWc7Ny2cYUg&s=10',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTRTPaxJqHeBvtse89BN70BIxPXi9msFEssiyErWQA98A&s=10',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRT7SSCiuPK9ksfJYTny4ibBP3r-C5sDp03Y6KUivrVeQ&s=10',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRDrmTaEY_vS1A5e4JlF4pmObE8Byu9Tm622N6MOB41Gw&s=10',
  ];

  static String proofPhoto(int index) =>
      proofPhotos[index % proofPhotos.length];

  // ---- 5. Avatar reviewer (6 Foto: Genap = Cowok, Ganjil = Cewek) ----
  static const List<String> reviewerAvatars = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjlNqra508DmZnyI33os2rWEwyzN47Tl5Iy_gU2Y8ZzA&s', // [0] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTG54lsQcYLkxT1Y6Lj1d-mLajrzVz1UmCQszaEnYcojA&s=10', // [1] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRfOKLo6UJUm50QqV_f-tG1zX_lQLPkUzo9YthyJi4agA&s=10', // [2] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQduDRj0ThOXYPIrAoLfrBj1IkrZFmxRbPJsZPaFG5O-A&s=10', // [3] Cewek
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_uBWS7AeDz78ffR7nWcJjf4NXWP7kzP3bykZ-M51XZA&s=10', // [4] Cowok
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT137QbDW9vOHTZr09qrdyuSiDwlg7VIWkd1OYct7-uOw&s=10', // [5] Cewek
  ];

  static String reviewerAvatar(int index) =>
      reviewerAvatars[index % reviewerAvatars.length];

  /// Helper tambahan jika ingin mengambil avatar reviewer spesifik berdasarkan gender
  static String reviewerAvatarByGender(int index, {required bool isFemale}) {
    final baseIndex = (index * 2) + (isFemale ? 1 : 0);
    return reviewerAvatars[baseIndex % reviewerAvatars.length];
  }
}