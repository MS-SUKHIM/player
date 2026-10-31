import 'package:flutter/material.dart';

enum ViewDesign { grid, list, folders, files, allFolders }

enum SortCriteria {
  title,
  date,
  watchTime,
  status,
  duration,
  size,
  resolution,
  path,
  frameRate,
  type,
}

enum SortDirection { asc, desc }

class MxViewOptionsDialog extends StatefulWidget {
  final ViewDesign currentDesign;
  final SortCriteria currentSort;
  final SortDirection currentDirection;
  final Function(ViewDesign, SortCriteria, SortDirection) onApply;

  const MxViewOptionsDialog({
    super.key,
    required this.currentDesign,
    required this.currentSort,
    required this.currentDirection,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required ViewDesign currentDesign,
    required SortCriteria currentSort,
    required SortDirection currentDirection,
    required Function(ViewDesign, SortCriteria, SortDirection) onApply,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => MxViewOptionsDialog(
        currentDesign: currentDesign,
        currentSort: currentSort,
        currentDirection: currentDirection,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MxViewOptionsDialog> createState() => _MxViewOptionsDialogState();
}

class _MxViewOptionsDialogState extends State<MxViewOptionsDialog> {
  late ViewDesign _selectedDesign;
  late SortCriteria _selectedSort;
  late SortDirection _selectedDirection;

  @override
  void initState() {
    super.initState();
    _selectedDesign = widget.currentDesign;
    _selectedSort = widget.currentSort;
    _selectedDirection = widget.currentDirection;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'طريقة العرض',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124),
                    ),
                  ),
                  Text(
                    'التصميم',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // صف أيقونات التصميم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDesignItem(
                    title: 'شبكة',
                    icon: Icons.grid_view_rounded,
                    type: ViewDesign.grid,
                  ),
                  _buildDesignItem(
                    title: 'قائمة',
                    icon: Icons.view_agenda_outlined,
                    type: ViewDesign.list,
                  ),
                  _buildDesignItem(
                    title: 'مجلدات',
                    icon: Icons.folder_outlined,
                    type: ViewDesign.folders,
                  ),
                  _buildDesignItem(
                    title: 'ملفات',
                    icon: Icons.insert_drive_file_outlined,
                    type: ViewDesign.files,
                  ),
                  _buildDesignItem(
                    title: 'كافة المجلدات',
                    icon: Icons.folder_copy_outlined,
                    type: ViewDesign.allFolders,
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
              const SizedBox(height: 14),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'فرز',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C4043),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSortItem(
                    title: 'العنوان',
                    icon: Icons.sort_by_alpha_rounded,
                    criteria: SortCriteria.title,
                  ),
                  _buildSortItem(
                    title: 'التاريخ',
                    icon: Icons.calendar_today_outlined,
                    criteria: SortCriteria.date,
                  ),
                  _buildSortItem(
                    title: 'وقت المشاهدة',
                    icon: Icons.history_rounded,
                    criteria: SortCriteria.watchTime,
                  ),
                  _buildSortItem(
                    title: 'الحالة',
                    icon: Icons.play_circle_outline_rounded,
                    criteria: SortCriteria.status,
                  ),
                  _buildSortItem(
                    title: 'المدة',
                    icon: Icons.slideshow_rounded,
                    criteria: SortCriteria.duration,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSortItem(
                    title: 'الحجم',
                    icon: Icons.sd_card_outlined,
                    criteria: SortCriteria.size,
                  ),
                  _buildSortItem(
                    title: 'الدقة',
                    icon: Icons.hd_outlined,
                    criteria: SortCriteria.resolution,
                  ),
                  _buildSortItem(
                    title: 'المسار',
                    icon: Icons.drive_file_move_outlined,
                    criteria: SortCriteria.path,
                  ),
                  _buildSortItem(
                    title: 'سرعة الإطار',
                    icon: Icons.speed_rounded,
                    criteria: SortCriteria.frameRate,
                  ),
                  _buildSortItem(
                    title: 'النوع',
                    icon: Icons.description_outlined,
                    criteria: SortCriteria.type,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // زري أ إلى ي / ي إلى أ
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(
                        () => _selectedDirection = SortDirection.asc,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedDirection == SortDirection.asc
                              ? const Color(0xFFE8F0FE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _selectedDirection == SortDirection.asc
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFFDADCE0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'أ إلى ي',
                              style: TextStyle(
                                color: _selectedDirection == SortDirection.asc
                                    ? const Color(0xFF1A73E8)
                                    : const Color(0xFF5F6368),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                              color: _selectedDirection == SortDirection.asc
                                  ? const Color(0xFF1A73E8)
                                  : const Color(0xFF5F6368),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(
                        () => _selectedDirection = SortDirection.desc,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedDirection == SortDirection.desc
                              ? const Color(0xFFE8F0FE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _selectedDirection == SortDirection.desc
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFFDADCE0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ي إلى أ',
                              style: TextStyle(
                                color: _selectedDirection == SortDirection.desc
                                    ? const Color(0xFF1A73E8)
                                    : const Color(0xFF5F6368),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 15,
                              color: _selectedDirection == SortDirection.desc
                                  ? const Color(0xFF1A73E8)
                                  : const Color(0xFF5F6368),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              _buildExpandableTile(title: 'الحقول'),
              const SizedBox(height: 8),
              _buildExpandableTile(title: 'متقدم'),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Color(0xFF5F6368),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: () {
                      widget.onApply(
                        _selectedDesign,
                        _selectedSort,
                        _selectedDirection,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'اكتمل',
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesignItem({
    required String title,
    required IconData icon,
    required ViewDesign type,
  }) {
    final isSelected = _selectedDesign == type;
    final color = isSelected
        ? const Color(0xFF1A73E8)
        : const Color(0xFF5F6368);

    return InkWell(
      onTap: () => setState(() => _selectedDesign = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortItem({
    required String title,
    required IconData icon,
    required SortCriteria criteria,
  }) {
    final isSelected = _selectedSort == criteria;
    final color = isSelected
        ? const Color(0xFF1A73E8)
        : const Color(0xFF5F6368);

    return InkWell(
      onTap: () => setState(() => _selectedSort = criteria),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableTile({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF5F6368),
            size: 20,
          ),
        ],
      ),
    );
  }
}
