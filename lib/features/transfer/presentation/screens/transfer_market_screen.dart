import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_ticket/features/transfer/presentation/screens/my_transfer_manage_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_guard.dart';
import '../providers/transfer_provider.dart';
import '../../data/transfer_models.dart';
import 'transfer_detail_screen.dart';
import 'private_transfer_screen.dart';

class TransferMarketScreen extends StatefulWidget {
  @override
  _TransferMarketScreenState createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  // 기존 필터 관련 변수들 (주석 처리하여 보존)
  // String _selectedFilter = '전체보기';
  // final List<String> _filterOptions = ['전체보기', '공연별로 보기'];

  // 검색 관련
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showPerformanceDropdown = false;

  // 공연 검색 관련
  final TextEditingController _performanceSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _performanceSearchResults = [];
  Map<String, dynamic>? _selectedPerformance;
  bool _isSearchingPerformances = false;
  final FocusNode _performanceSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    // 포커스 리스너 추가
    _performanceSearchFocusNode.addListener(() {
      setState(() {
        _showPerformanceDropdown = _performanceSearchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _performanceSearchController.dispose();
    _performanceSearchFocusNode.dispose();
    super.dispose();
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );
    await transferProvider.loadTransferTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '양도 마켓',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPurposeHeader(),
          _buildPerformanceSearchBar(),
          if (_selectedPerformance != null) _buildSelectedPerformanceCard(),
          _buildActionButtons(),
          Expanded(child: _buildTransferTicketList()),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPurposeHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 15),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              '모바일 신분증 인증이 완료된 사용자만 양도 거래가 가능합니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Row(
            children: [
              // 공연 검색창
              Expanded(
                flex: 6,
                child: Container(
                  height: 45,
                  child: TextField(
                    controller: _performanceSearchController,
                    focusNode: _performanceSearchFocusNode,
                    decoration: InputDecoration(
                      hintText: '공연명으로 검색...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_performanceSearchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _performanceSearchController.clear();
                                _clearPerformanceSearch();
                              },
                            ),
                          if (_selectedPerformance != null)
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '선택됨',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    onChanged: _onPerformanceSearchChanged,
                  ),
                ),
              ),

              SizedBox(width: 8),

              // 양도관리 버튼
              GestureDetector(
                onTap: () {
                  AuthGuard.requireAuth(
                    context,
                    onAuthenticated: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyTransferManageScreen(),
                        ),
                      );
                    },
                    message: '양도 관리는 로그인이 필요합니다',
                  );
                },
                child: Container(
                  height: 45,
                  width: 45,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Icon(Icons.person, color: AppColors.secondary),
                ),
              ),

              SizedBox(width: 6),

              // 비공개 버튼
              GestureDetector(
                onTap: () {
                  AuthGuard.requireAuth(
                    context,
                    onAuthenticated: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivateTransferScreen(),
                        ),
                      );
                    },
                    message: '비공개 양도는 로그인이 필요합니다',
                  );
                },

                child: Container(
                  height: 45,
                  width: 45,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Icon(Icons.lock, color: AppColors.secondary),
                ),
              ),
            ],
          ),

          // 공연 검색 결과 드롭다운
          if (_showPerformanceDropdown && _performanceSearchResults.isNotEmpty)
            Positioned(
              top: 53,
              left: 0,
              right: 140, // 버튼 영역 제외
              child: _buildPerformanceDropdown(),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDropdown() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _performanceSearchResults.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final performance = _performanceSearchResults[index];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              performance['title'] ?? '',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${performance['venue'] ?? ''} • ${performance['date'] ?? ''}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _selectPerformance(performance),
          );
        },
      ),
    );
  }

  Widget _buildSelectedPerformanceCard() {
    if (_selectedPerformance == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택된 공연',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _selectedPerformance!['title'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.primary, size: 18),
            onPressed: _clearSelectedPerformance,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '전체 양도 티켓',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Spacer(),
          if (_selectedPerformance != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '필터링 중',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 기존 코드 보존 - 주석 처리된 기존 필터 위젯
  /*
 Widget _buildFilterAndActions() {
   return Container(
     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     child: Column(
       children: [
         Row(
           children: [
             Expanded(
               child: Container(
                 padding: EdgeInsets.symmetric(horizontal: 12),
                 decoration: BoxDecoration(
                   color: AppColors.surface,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: AppColors.border),
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String>(
                     value: _selectedFilter,
                     items: _filterOptions.map((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Text(
                           value,
                           style: TextStyle(
                             fontSize: 14,
                             color: AppColors.textPrimary,
                           ),
                         ),
                       );
                     }).toList(),
                     onChanged: (String? newValue) {
                       setState(() {
                         _selectedFilter = newValue!;
                       });
                       _applyFilter(newValue!);
                     },
                     icon: Icon(
                       Icons.arrow_drop_down,
                       color: AppColors.textSecondary,
                     ),
                   ),
                 ),
               ),
             ),
             Row(
               children: [
                 SizedBox(width: 4),
                 GestureDetector(
                   onTap: () {
                     AuthGuard.requireAuth(
                       context,
                       onAuthenticated: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => MyTransferManageScreen(),
                           ),
                         );
                       },
                       message: '양도 관리는 로그인이 필요합니다',
                     );
                   },
                   child: Container(
                     alignment: Alignment.center,
                     width: 45,
                     height: 45,
                     padding: EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: AppColors.gray200,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: AppColors.gray300),
                     ),
                     child: Icon(Icons.person, color: AppColors.secondary),
                   ),
                 ),
                 SizedBox(width: 4),
                 GestureDetector(
                   onTap: () {
                     AuthGuard.requireAuth(
                       context,
                       onAuthenticated: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (context) => PrivateTransferScreen(),
                           ),
                         );
                       },
                       message: '비공개 양도는 로그인이 필요합니다',
                     );
                   },
                   child: Container(
                     width: 45,
                     height: 45,
                     alignment: Alignment.center,
                     padding: EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: AppColors.gray200,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: AppColors.gray300),
                     ),
                     child: Icon(Icons.lock, color: AppColors.secondary),
                   ),
                 ),
               ],
             ),
           ],
         ),
       ],
     ),
   );
 }
 */

  Widget _buildTransferTicketList() {
    return Consumer<TransferProvider>(
      builder: (context, transferProvider, child) {
        // 로딩 상태
        if (transferProvider.isLoading &&
            transferProvider.transferTickets == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  '양도 티켓 목록을 불러오는 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // 에러 상태
        if (transferProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                SizedBox(height: 16),
                Text(
                  transferProvider.errorMessage!,
                  style: TextStyle(fontSize: 16, color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    transferProvider.clearError();
                    _refreshTickets();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final filteredTickets = transferProvider.filteredTransferTickets;

        // 데이터 없음
        if (filteredTickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  _selectedPerformance != null
                      ? '선택한 공연의 양도 티켓이 없습니다'
                      : '현재 양도 중인 티켓이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _selectedPerformance != null
                      ? '다른 공연을 선택해보세요'
                      : '새로고침을 통해 최신 목록을 확인해보세요',
                  style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          );
        }

        // 양도 티켓 리스트
        return RefreshIndicator(
          color: AppColors.warning,
          onRefresh: _refreshTickets,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount:
                filteredTickets.length + (transferProvider.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              // 로딩 인디케이터 (하단에 표시)
              if (index == filteredTickets.length &&
                  transferProvider.isLoading) {
                return Container(
                  padding: EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final ticket = filteredTickets[index];
              return _buildTransferTicketCard(ticket);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransferTicketCard(TransferTicketItem ticket) {
    final sessionDate = DateTime.parse(ticket.sessionDatetime);
    final now = DateTime.now();
    final timeUntilSession = sessionDate.difference(now);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransferDetailScreen(transferTicketId: ticket.transferTicketId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 시간 정보
                  if (timeUntilSession.inDays >= 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: timeUntilSession.inDays <= 7
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        timeUntilSession.inDays == 0
                            ? '오늘 공연'
                            : timeUntilSession.inDays <= 7
                            ? 'D-${timeUntilSession.inDays}'
                            : '${timeUntilSession.inDays}일 후',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: timeUntilSession.inDays <= 7
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  // 양도 등록 시간
                  Text(
                    _formatTimeAgo(DateTime.parse(ticket.createdDatetime)),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // 포스터 이미지
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.gray300,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ticket.performanceMainImage != null
                          ? Image.network(
                              ticket.performanceMainImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.gray300,
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 30,
                                    color: AppColors.gray600,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.gray300,
                              child: Icon(
                                Icons.music_note,
                                size: 30,
                                color: AppColors.gray600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // 공연 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.performanceTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4),

                        Text(
                          ticket.performerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 8),

                        _buildInfoRow(
                          Icons.calendar_today,
                          _formatSessionDateTime(sessionDate),
                        ),
                        SizedBox(height: 4),
                        _buildInfoRow(Icons.location_on, ticket.venueName),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌석 정보
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '좌석 정보',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ticket.seatNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '양도 가격',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ticket.priceDisplay,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // === 새로운 공연 검색 관련 메서드들 ===

  /// 공연 검색어 변경 시 호출
  void _onPerformanceSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _performanceSearchResults.clear();
        _showPerformanceDropdown = false;
      });
      return;
    }

    // TODO: 실제 공연 검색 API 호출
    _searchPerformances(query);
  }

  /// 공연 검색 API 호출
  Future<void> _searchPerformances(String query) async {
    if (query.length < 2) return; // 최소 2글자 이상 입력 시 검색

    setState(() {
      _isSearchingPerformances = true;
    });

    try {
      // TODO: 실제 API 호출로 교체
      // final response = await ApiService.searchPerformances(query);
      // List<Map<String, dynamic>> results = response.data;

      // 임시 더미 데이터
      await Future.delayed(Duration(milliseconds: 300)); // API 호출 시뮬레이션

      List<Map<String, dynamic>> results =
          [
                {
                  'id': '1',
                  'title': '아이유 콘서트 2025',
                  'venue': '올림픽공원 체조경기장',
                  'date': '2025.03.15',
                  'performerId': 'iu_2025',
                },
                {
                  'id': '2',
                  'title': 'BTS 월드투어',
                  'venue': '잠실종합운동장',
                  'date': '2025.04.20',
                  'performerId': 'bts_2025',
                },
              ]
              .where(
                (performance) => performance['title']!.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

      setState(() {
        _performanceSearchResults = results;
        _showPerformanceDropdown = results.isNotEmpty;
        _isSearchingPerformances = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingPerformances = false;
        _performanceSearchResults.clear();
        _showPerformanceDropdown = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('공연 검색 중 오류가 발생했습니다')));
    }
  }

  /// 공연 선택
  void _selectPerformance(Map<String, dynamic> performance) {
    setState(() {
      _selectedPerformance = performance;
      _performanceSearchController.text = performance['title'] ?? '';
      _showPerformanceDropdown = false;
    });

    _performanceSearchFocusNode.unfocus();
    _applyPerformanceFilter(performance['id']);
  }

  /// 공연 검색 초기화
  void _clearPerformanceSearch() {
    setState(() {
      _performanceSearchResults.clear();
      _showPerformanceDropdown = false;
    });
  }

  /// 선택된 공연 초기화
  void _clearSelectedPerformance() {
    setState(() {
      _selectedPerformance = null;
      _performanceSearchController.clear();
      _showPerformanceDropdown = false;
    });

    // TODO: 전체 목록으로 다시 로드
    _applyPerformanceFilter(null);
  }

  /// 공연별 필터 적용
  void _applyPerformanceFilter(String? performanceId) {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );

    // TODO: TransferProvider에 공연별 필터 메서드 추가
    // transferProvider.setPerformanceFilter(performanceId);

    // 임시로 기존 메서드 사용 (실제 구현 시 교체)
    if (performanceId != null) {
      // TODO: API 호출로 해당 공연의 양도 티켓만 가져오기
      // transferProvider.loadTransferTicketsByPerformance(performanceId);
      print('필터 적용: 공연 ID $performanceId');
    } else {
      // 전체 목록으로 복구
      transferProvider.loadTransferTickets(forceRefresh: true);
    }
  }

  // === 기존 메서드들 (보존) ===

  /// 검색 수행 (기존 메서드 - 보존)
  void _performSearch(String query) {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );
    transferProvider.setSearchQuery(query);
  }

  /// 필터 적용 (기존 메서드 - 보존)
  /*
  void _applyFilter(String filter) {
    // TODO: 공연별 필터링 구현
    if (filter == '공연별로 보기') {
      // 공연 목록을 보여주고 선택하게 하는 다이얼로그나 새 화면
      _showPerformanceFilterDialog();
    } else {
      // 전체보기
      final transferProvider = Provider.of<TransferProvider>(
        context,
        listen: false,
      );
      transferProvider.setPerformanceFilter(null);
    }
  }
  */

  /// 공연별 필터 다이얼로그 (기존 메서드 - 보존)
  /*
  void _showPerformanceFilterDialog() {
    // TODO: 공연 목록 API 연결 후 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('공연별 필터링 기능 준비 중입니다')));
  }
  */

  /// 시간 형식 변환
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 세션 날짜 시간 형식 변환
  String _formatSessionDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 새로고침
  Future<void> _refreshTickets() async {
    final transferProvider = Provider.of<TransferProvider>(
      context,
      listen: false,
    );
    await transferProvider.loadTransferTickets(forceRefresh: true);
  }
}
