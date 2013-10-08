

class EmployeesSubject < ActiveRecord::Base
    belongs_to :employee
    belongs_to :subject
    has_one :batch,:through=>:subject

  def self.allot_work(employee_subj_ids)
    status,error_carrier = false,self.new
    self.transaction do
      emp_subjs = []
      employee_subj_ids.each do |subj_id,emp_id|
        a = self.find_or_create_by_subject_id(:subject_id=>subj_id)
        a.employee_id = emp_id
        a.save
        emp_subjs << a
      end

      employee_assignments = emp_subjs.group_by{|es|es.employee_id}
      emp_assigned_hours = {}
      employee_assignments.each do |emp_id,emp_subs|
        emp_assigned_hours[emp_id] ||= {}
        emp_assigned_hours[emp_id][:assigned]=emp_subs.sum{|es| es.subject.max_weekly_classes} || 0
        emp_assigned_hours[emp_id][:max]=emp_subs.first.employee.max_hours_week || 0
        emp_assigned_hours[emp_id][:emp_name]=emp_subs.first.employee.full_name 
      end
      overloaded_emps = emp_assigned_hours.reject{|emp_id,details| details[:assigned].to_i <= details[:max].to_i}
      status = overloaded_emps.blank?

      
      unless overloaded_emps.blank?
        puts overloaded_emps.inspect
        overloaded_emps.each do |emp_id,details|
          error_carrier.errors.add_to_base("#{details[:emp_name]} has #{details[:assigned]-details[:max].to_i} extra periods assigned")
        end
#        raise ActiveRecord::Rollback
      end
    end
    return [status,error_carrier]
  end
        
        
end