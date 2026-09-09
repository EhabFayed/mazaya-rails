# Downloadable documents (catalogs, TDS, certificates). `key` is what the
# public /downloads/:key route and the gate forms use.
module Admin
  class DocumentsController < BaseController
    before_action :require_content!
    before_action :set_document, only: %i[edit update destroy]

    def admin_section = "documents"

    def index
      @documents = Document.ordered.with_attached_file
    end

    def new
      @document = Document.new(published: true, gated: true, doc_type: "catalog")
    end

    def create
      @document = Document.new(document_params)
      if @document.save
        redirect_to edit_admin_document_path(@document), notice: "تم الحفظ."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @document.update(document_params)
        redirect_to edit_admin_document_path(@document), notice: "تم الحفظ."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @document.destroy
      redirect_to admin_documents_path, notice: "تم حذف الوثيقة."
    end

    private

    def set_document = @document = Document.find(params[:id])

    def document_params
      attrs = params.require(:document).permit(:key, :doc_type, :title_ar, :title_en, :desc_ar, :desc_en, :cta_ar, :cta_en,
                                               :gated, :version, :version_date, :file, :position, :published)
      attrs.delete(:file) if attrs[:file].blank?
      attrs
    end
  end
end
